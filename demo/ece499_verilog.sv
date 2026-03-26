/*
 * SPDX-License-Identifier: MIT
 * Author: Anthony Kung <hi@anth.dev> (anth.dev)
 *
 * Tiny GEMM demo
 */

`timescale 1ns / 1ps
`default_nettype none

module gemm_2x2 #(
  parameter int DATA_W = 8,
  parameter int ACC_W = 2 * DATA_W + 2
) (
  input  logic signed [DATA_W-1:0] a [2][2],
  input  logic signed [DATA_W-1:0] b [2][2],
  output logic signed [ACC_W-1:0]  c [2][2]
);
  always_comb begin : gemm_comb
    for (int row = 0; row < 2; row++) begin
      for (int col = 0; col < 2; col++) begin
        c[row][col] = '0;
        for (int k = 0; k < 2; k++) begin
          c[row][col] += a[row][k] * b[k][col];
        end
      end
    end
  end
endmodule

module gemm_2x2_tb;
  localparam int DATA_W = 8;
  localparam int ACC_W = 2 * DATA_W + 2;

  logic signed [DATA_W-1:0] a [2][2];
  logic signed [DATA_W-1:0] b [2][2];
  logic signed [ACC_W-1:0]  c [2][2];

  gemm_2x2 #(
    .DATA_W(DATA_W),
    .ACC_W(ACC_W)
  ) dut (
    .a(a),
    .b(b),
    .c(c)
  );

  task automatic load_case(
    input logic signed [DATA_W-1:0] a_in [2][2],
    input logic signed [DATA_W-1:0] b_in [2][2]
  );
    a = a_in;
    b = b_in;
    #1;
  endtask

  task automatic check_case(
    input string name,
    input logic signed [ACC_W-1:0] expected [2][2]
  );
    for (int row = 0; row < 2; row++) begin
      for (int col = 0; col < 2; col++) begin
        assert (c[row][col] == expected[row][col])
          else $error(
            "%s mismatch at c[%0d][%0d]: got %0d expected %0d",
            name,
            row,
            col,
            c[row][col],
            expected[row][col]
          );
      end
    end

    $display(
      "%s passed: [[%0d, %0d], [%0d, %0d]]",
      name,
      c[0][0], c[0][1],
      c[1][0], c[1][1]
    );
  endtask

  initial begin
    logic signed [DATA_W-1:0] a_case0 [2][2] = '{
      '{1, 2},
      '{3, 4}
    };
    logic signed [DATA_W-1:0] b_case0 [2][2] = '{
      '{5, 6},
      '{7, 8}
    };
    logic signed [ACC_W-1:0] expected0 [2][2] = '{
      '{19, 22},
      '{43, 50}
    };

    logic signed [DATA_W-1:0] a_case1 [2][2] = '{
      '{2, -1},
      '{0, 3}
    };
    logic signed [DATA_W-1:0] b_case1 [2][2] = '{
      '{4, 1},
      '{-2, 5}
    };
    logic signed [ACC_W-1:0] expected1 [2][2] = '{
      '{10, -3},
      '{-6, 15}
    };

    load_case(a_case0, b_case0);
    check_case("case0", expected0);

    load_case(a_case1, b_case1);
    check_case("case1", expected1);

    $finish;
  end
endmodule

`default_nettype wire
