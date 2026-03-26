"""
SPDX-License-Identifier: MIT
Author: Anthony Kung <hi@anth.dev> (anth.dev)

Tiny Transformer demo
"""

from __future__ import annotations

from dataclasses import dataclass
from math import exp, sqrt
from typing import Sequence, TypeAlias

Vector: TypeAlias = list[float]
Matrix: TypeAlias = list[Vector]
VectorLike: TypeAlias = Sequence[float]


def dot(lhs: VectorLike, rhs: VectorLike) -> float:
    return sum(left * right for left, right in zip(lhs, rhs, strict=True))


def matmul_row(vector: Vector, matrix: Matrix) -> Vector:
    return [dot(vector, column) for column in zip(*matrix, strict=True)]


def softmax(values: Vector) -> Vector:
    peak = max(values)
    exps = [exp(value - peak) for value in values]
    total = sum(exps)
    return [value / total for value in exps]


@dataclass(slots=True)
class TinyTransformer:
    d_model: int
    tokens: dict[str, Vector]
    w_q: Matrix
    w_k: Matrix
    w_v: Matrix

    def encode(self, prompt: list[str]) -> Matrix:
        return [self.tokens[token] for token in prompt]

    def attention(self, prompt: list[str]) -> Matrix:
        embeddings = self.encode(prompt)
        queries = [matmul_row(row, self.w_q) for row in embeddings]
        keys = [matmul_row(row, self.w_k) for row in embeddings]
        values = [matmul_row(row, self.w_v) for row in embeddings]
        scale = sqrt(self.d_model)

        output: Matrix = []
        for query in queries:
            scores = [dot(query, key) / scale for key in keys]
            weights = softmax(scores)
            mixed = [
                sum(weight * value[idx] for weight, value in zip(weights, values, strict=True))
                for idx in range(self.d_model)
            ]
            output.append(mixed)

        return output


if __name__ == "__main__":
    model = TinyTransformer(
        d_model=4,
        tokens={
            "<bos>": [1.0, 0.0, 0.0, 1.0],
            "carrot": [0.8, 0.2, 0.1, 0.9],
            "theme": [0.3, 0.9, 0.4, 0.2],
            "glows": [0.2, 0.5, 1.0, 0.1],
        },
        w_q=[
            [0.9, 0.1, 0.0, 0.2],
            [0.1, 0.8, 0.2, 0.0],
            [0.0, 0.3, 0.7, 0.4],
            [0.2, 0.0, 0.1, 0.9],
        ],
        w_k=[
            [0.8, 0.0, 0.2, 0.1],
            [0.2, 0.7, 0.1, 0.0],
            [0.1, 0.2, 0.9, 0.3],
            [0.0, 0.1, 0.2, 0.8],
        ],
        w_v=[
            [1.0, 0.0, 0.0, 0.1],
            [0.0, 1.0, 0.1, 0.0],
            [0.1, 0.1, 0.9, 0.2],
            [0.2, 0.0, 0.2, 0.8],
        ],
    )

    prompt = ["<bos>", "carrot", "theme", "glows"]
    hidden = model.attention(prompt)

    for token, state in zip(prompt, hidden, strict=True):
        rounded = ", ".join(f"{value:.3f}" for value in state)
        print(f"{token:>7} -> [{rounded}]")
