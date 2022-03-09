from fastapi import FastAPI, HTTPException
import timeit
from pydantic import BaseModel
from typing import Any as any

# example_model is the only thing you need to change
from model.model import predictors


# All test may not be runnable at container generation time

starttime = timeit.default_timer()
app = FastAPI()


class JSONWrapper(BaseModel):
    predictor: str
    payload: any


def select(name):
    cands = [p for p in predictors if p.name == name]
    if len(cands) > 1:
        raise HTTPException(status_code=500, detail="Model " + name + " not unique")
    elif len(cands) == 0:
        raise HTTPException(status_code=400, detail="Model " + name + " not found")
    return cands[0]


@app.get("/health/live")
async def health_live():
    return "LIVE"


@app.get("/livez")
async def livez():
    return "LIVE"


@app.get("/health/ready/")
async def health_ready(model: str):
    if select(model).self_test():
        return "READY"
    else:
        raise HTTPException(status_code=503, detail="NOT_READY")


@app.get("/readyz")
async def readyz():
    if all([p.self_test() for p in predictors]):
        return "READY"
    else:
        raise HTTPException(status_code=503, detail="Predictor(s) not ready")


@app.get("/healthz")
async def healthz():
    if all([p.self_test() for p in predictors]):
        return "READY"
    else:
        raise HTTPException(status_code=503, detail="Predictor(s) not ready")


@app.get("/health/uptime")
async def health_uptime():
    return timeit.default_timer() - starttime


@app.get("/predict_schema/")
async def p_schema(model: str):
    return select(model).p_schema


@app.get("/score_schema/")
async def s_schema(model: str):
    return select(model).s_schema


@app.get("/list")
async def list():
    return [p.name for p in predictors]


@app.get("/health")
async def health():
    return {
        "live": True,
        "ready": {p.name: p.self_test() for p in predictors},
        "uptime": timeit.default_timer() - starttime,
    }


@app.get("/version/")
async def version(model):
    return select(model).version


@app.get("/creation_time/")
async def created(model: str):
    return select(model).created


@app.post("/predict/")
async def model_predict(argument: JSONWrapper):
    return select(argument.predictor).predict(argument.payload)


@app.post("/score/")
async def model_score(argument: JSONWrapper):
    return select(argument.predictor).score(argument.payload)
