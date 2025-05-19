from models import Person, People, Log
from ocr import ocr_aadhaar

people = People(count=0, people_in=[], people_out=[], logs=[])

def add_person(path: str, isDigital: bool):
    print("inside add_person")
    result = ocr_aadhaar(path, isDigital)
    print("OCR result:", result)
    print("List of people in : "+ str(people.people_in))
    if isDigital:
        aadhar = result["details"]["aadhar_4_dgts"]
    else:
        aadhar = result["details"]["aadhar_number"]

    name = result["details"]["full_name"]
    if not aadhar or not name:
        raise ValueError("Aadhar number or name not found in OCR result")

    if(str(aadhar) in [str(i.aadhar) for i in people.people_in]):
        print("MATCHED")
        raise ValueError("Person already exists")
    
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
            people.people_out.append(i)
            return True
    return False

def get_people_in():
    names = [i.name for i in people.people_in]
    return names

def get_people_out():
    names = [i.name for i in people.people_out]
    return names

def get_logs():
    logs = [(i.person.name, i.isIn) for i in people.logs]
    return logs


def get_person_details(aadhar: str):
    # Convert to string for comparison if needed
    aadhar_str = str(aadhar)
    
    # Check in people_in list first
    for person in people.people_in:
        if str(person.aadhar) == aadhar_str:
            # Find the original OCR data if available
            # For simplicity, we'll return basic info
            return {
                "aadharNumber": person.aadhar,
                "name": person.name,
                "dob": "Not available",  # We don't store this in Person model
                "gender": "Not available"  # We don't store this in Person model
            }
    
    # Check in people_out list if not found
    for person in people.people_out:
        if str(person.aadhar) == aadhar_str:
            return {
                "aadharNumber": person.aadhar,
                "name": person.name,
                "dob": "Not available",
                "gender": "Not available"
            }
    
    # Person not found
    return None