from sklearn.linear_model import LogisticRegressionCV
import numpy as np
import json
from jsonschema import validate
from predictor import Predictor


class LogReg(Predictor):
    def convert_prediction_input(self, x):
        return np.asfarray(x)

    def convert_output(self, res):
        return res.tolist()

    def convert_score_input(self, in_object):
        X = [item["x"] for item in in_object]
        y = [item["y"] for item in in_object]
        return np.asfarray(X), np.array(y)

    def run_scores(self, X, y):
        return self.model.score(X, y)

    def run_predict(self, X):
        return self.model.predict(X)

    # def main():


N = 30
Nf = 3
X = np.random.randn(N, Nf)
y = np.random.randn(N) > 0.0
lr1 = LogisticRegressionCV(fit_intercept=True)
lr1.fit(X, y)
test_input = np.random.randn(2, Nf).tolist()
print(test_input)
X = np.random.randn(N, Nf)
y = [bool(t) for t in np.random.randn(N) > 0.0]
lr2 = LogisticRegressionCV(fit_intercept=True)
lr2.fit(X, y)

# Input x is an array of exactly Nf numbers
x_schema = {
    "type": "array",
    "minItems": Nf,
    "maxItems": Nf,
    "items": {"type": "number"},
}

y_schema = {"type": "boolean"}

# One or more inputs
pred_schema = {
    "type": "array",
    "minItems": 1,
    "items": x_schema,
}

# One or more objects with x and y
score_schema = {
    "type": "array",
    "minItems": 1,
    "items": {
        "type": "object",
        "properties": {
            "x": x_schema,
            "y": y_schema,
        },
    },
}

score_test_input = [{"x": X[ind, :].tolist(), "y": y[ind]} for ind in range(X.shape[0])]

predictors = [
    LogReg(
        lr1,
        "test_logreg1",
        test_input,
        pred_schema,
        score_test_input,
        score_schema,
    ),
    LogReg(
        lr2,
        "test_logreg2",
        test_input,
        pred_schema,
        score_test_input,
        score_schema,
    ),
]
