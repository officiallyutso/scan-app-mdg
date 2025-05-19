from pydantic import BaseModel
from typing import List

class Person(BaseModel):
    aadhar: int
    name: str

class Log(BaseModel):
    person: Person
    isIn: bool

class People(BaseModel):
    count: int
    people_in: List[Person]
    logs: List[Log]