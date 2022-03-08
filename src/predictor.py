import datetime as dt
from abc import ABC
import json
from typing import Any as any
from jsonschema import validate


class Predictor(ABC):
    def __init__(
        self,
        model,
        name: str,
        test_input: str,
        pred_schema: dict,
        score_test_input: str,
        score_schema: dict,
        version="v1",
    ):
        """
        test_input is a string that contains in JSON format a feasible input,
        such that after a parse_input the __call__ method can be tested with it.
        """
        self.model = model
        self.p_schema = pred_schema
        # Make sure the schema and prediction test input match
        self._validate_pred_input(test_input)
        self._test_input = test_input
        self.s_schema = score_schema
        # Make sure the schema and score test input match
        self._validate_score_input(score_test_input)
        self._score_test_input = score_test_input
        if not self.self_test():
            raise ValueError
        self.name = name
        self.version = version
        self.created = str(dt.datetime.utcnow())

    def _validate_pred_input(self, sent: any):
        validate(sent, self.p_schema)

    def _validate_score_input(self, sent: any):
        validate(sent, self.s_schema)

    def convert_prediction_input(self, sent: str):
        raise NotImplementedError

    def convert_output(self, res):
        """
        Converts the prediction result to a format that is readily convertable to JSON
        By default, send the result as is
        """
        return res

    def self_test(self):
        try:
            json.dumps(self(self._test_input))
            json.dumps(self.score(self._score_test_input))
        except ValueError:
            return False
        except NotImplementedError:  # Some required method not yet implemented
            return False
        except TypeError:  # Not JSONable
            False
        return True

    def convert_score_input(self, score_input_object):
        raise NotImplementedError

    def run_scores(self, X, y):
        raise NotImplementedError

    def score(self, score_input: any):
        """
        Monitors that the predictor still performs adequately
        """
        try:
            self._validate_score_input(score_input)
            X, y = self.convert_score_input(score_input)
        except NotImplementedError as ex:
            raise NotImplementedError(
                " Please provide implementation for your Predictor subclass's convert_score_input"
            )
        try:
            return self.run_scores(X, y)
        except NotImplementedError as ex:
            raise NotImplementedError(
                " Please provide the run_scores-method for your Predictor subclass"
            )

    def predict(self, X: any) -> any:
        raise NotImplementedError

    def __call__(self, sent: any):
        try:
            self._validate_pred_input(sent)
            X = self.convert_prediction_input(sent)
        except NotImplementedError as ex:
            raise NotImplementedError(
                " Please provide implementation for your Predictor subclass's convert_prediction_input"
            )
        res = self.predict(X)
        return self.convert_output(res)
