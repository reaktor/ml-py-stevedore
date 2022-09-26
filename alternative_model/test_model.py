from model.model import predictors

def test_predictor():

    assert predictors[0].name == "test_logreg3"
    assert predictors[0].self_test()
    assert predictors[1].self_test()

