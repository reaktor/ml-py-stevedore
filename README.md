# ml-py-stevedore

Wrapper class and generic API plus Podman/Docker build automation for
Python ML models. A specific use case is a set of machine learning
models that may be composed, so that they should be tested and packaged
together. This by no means excludes use on single model.

## Purpose

`ml-py-stevedore` speeds up stuffing your Python ML models into a
container with useful premeditated standard services, naturally
presented requirements for the functionality of the model, and build &
test automation.

The services of the API enable monitoring of the models, queries to
support their use and calls to the model prediction. The services are

 * health services such as
    - `livez`
    - `healthz`
    - `readyz`
    - `score`
    - variants of the above
 * catalogs
    - `list` the models being served
    - `version` of each model
    - `created` tells the creation time
    - `predict_schema` and `score_schema` return the JSON schemas for prediction and scoring input
 * `predict` - of course.

The assumptions are
 * Request payload is presented as JSON in the body.
 * For each model, the user supplies
    - a JSONschema for prediction and scoring inputs,
    - a couple of key methods that are missing in the base class, and
    - test inputs for predict and score to honestly test the model availability.

As the HTTP-framework that serves the API is FastAPI, a Swagger
documentation of the API is also served up to the user-defined
JSONschemas.

## Use instructions

### Basic requirements
ml-py-stevedore depends on `Python 3.9` or higher and `docker` or `podman`.

### Models

You need to build your models and probably persist them in some manner,
e.g. `HDF5`, `onnx` or such. N.B. Python's `pickle` is not a good
choice due to compatibility problems between different versions and
platforms.

You need to take care of your model's dependencies. You can modify the
`requirements.txt`-file to add the required dependencies.

Place the models in one Python module and build a list called
`predictors` of your `Predictor` subclasses' objects. Then introduce
the name of the module into the import statement at the beginning of
`source/predictor.py` instead of the `example_model`:

    from example_model import predictors



## Design

The `Predictor` abstract base class enables quick construction of a
derived class that wraps the ML-model. The methods of the base class
are crafted to back the generic API. In particular, the user must fill
in a couple of methods:

  * conversion of JSON-parsed and validated API input value into the value accepted by the ML model prediction. The input value may be an URL, an array of numbers - the existence of this method makes the package very flexible.
  * `run_predict`-method (think of `sklearn`)
  * conversion of JSON-parsed and validated API input value into the values `X,y` accepted by the ML model scoring. Again, the setting is very flexible.
  * `run_scores`-method
  * conversion of the prediction return value to a readily JSONable type.

To get an idea how any machine learning model can be interfaced with
the generic API, let's look at the sklearn logistic regressor example
in `example_model.py`:

```
  class LogReg(Predictor):
    def convert_prediction_input(self, x):
        return np.asfarray(x)

    def convert_score_input(self, in_object):
        X = [item["x"] for item in in_object]
        y = [item["y"] for item in in_object]
        return np.asfarray(X), np.array(y)

    def run_scores(self, X, y):
        return self.model.score(X, y)

    def run_predict(self, X):
        return self.model.predict(X)

    def convert_output(self, res):
        return res.tolist()
```

The method `convert_prediction_input` makes sure we are feeding in a
numpy array. When the conversion methods get called, we already know
that inputs have been validated againts the initialization-time
JSONschemas.  `convert_score_input` separates test inputs `X` and
ground truths `y` from the input. `run_scores` transparently relies on
the sklearn model's score - but could do a number of KPIs in one
stroke. Finally, `run_predict` transparently runs the prediction method
of the sklearn model. In the backgrount, the constructor of the class
runs instatiation-time tests to prevent junk-serving and input
validations are run for all requests. Finally, the method
`convert_output` converts the prediction result into a list - thus
readily JSONable.
