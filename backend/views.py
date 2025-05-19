from models import Person, People, Log
from ocr import get_aadhar

people = People(count=0, people_in=[], logs=[])

def add_person(file: str):
    aadhar, name = ocr(file)
    person = Person(aadhar=aadhar, name=name)
    people.people_in.append(person)
    people.count += 1
    log = Log(person=person, isIn=True)
    people.logs.append(log)
    return aadhar, name

def remove_person(aadhar: int):
    for i in people.people_in:
        if i.aadhar == aadhar:
            people.people_in.remove(i)
            people.count -= 1
            log = Log(person=i, isIn=False)
            people.logs.append(log)
            return True
    return False

def get_people_in():
    names = [i.name for i in people.people_in]
    return names

def get_logs():
    logs = [(i.person.name, i.isIn) for i in people.logs]
    return logs
