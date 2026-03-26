/*
 * SPDX-License-Identifier: MIT
 * Author: Anthony Kung <hi@anth.dev> (anth.dev)
 *
 * Tiny demo SystemC module created for AI539 class
 * at Oregon State University, Fall 2025
 * See https://ta.anth.dev
 */

#include <systemc>

using namespace sc_core;
using namespace sc_dt;

#define VCD_NAME "waveform"

SC_MODULE(Dispense)
{
  sc_in<bool> clk;
  sc_in<bool> rst_n; // Active low reset
  sc_in<bool> enable;
  sc_out<bool> done;

  sc_uint<4> count;

  void dispense_logic()
  {
    count = 0;
    done.write(false);
    wait(); // Wait for the first clock edge

    while (true)
    {
      // If reset is active, reset stuff
      if (!rst_n.read())
      {
        count = 0;
        done.write(false);
      }
      // if not reset, check enable
      else if (enable.read())
      {
        if (count < 15)
        {
          count++;
          if (count == 15)
          {
            done.write(true);
            count = 0; // Reset count after done
          }
        }
      }
      wait(); // Wait for next clock edge
    }
  }

  SC_CTOR(Dispense)
  {
    SC_CTHREAD(dispense_logic, clk.pos());
  }
};

int sc_main()
{
  sc_trace_file *tf{nullptr};
  tf = sc_create_vcd_trace_file(VCD_NAME);
  if (!tf)
  {
    SC_REPORT_ERROR("SC_MAIN", "Failed to open VCD; aborting");
    return 1;
  }

  // Clock
  sc_clock clk("clk", 10, SC_NS);

  // Signals
  sc_signal<bool> rst_n;
  sc_signal<bool> enable;
  sc_signal<bool> done;

  // module
  Dispense random_module("random_module");
  random_module.clk(clk);
  random_module.rst_n(rst_n);
  random_module.enable(enable);
  random_module.done(done);

  // Trace signals
  sc_trace(tf, clk, "clk");
  sc_trace(tf, rst_n, "rst_n");
  sc_trace(tf, enable, "enable");
  sc_trace(tf, done, "done");

  sc_start();

  // Initialize signals
  clk.write(false);
  rst_n.write(false);
  enable.write(false);

  // Simulation
  sc_start(10, SC_NS);
  rst_n.write(true);    // Release reset
  enable.write(true);   // Enable dispensing
  sc_start(200, SC_NS); // Run simulation for some time
  enable.write(false);  // Disable dispensing
  std::cout << "Final done signal: " << done.read() << std::endl;

  if (tf)
  {
    sc_close_vcd_trace_file(tf);
  }
  return 0;
}