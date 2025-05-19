from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from views import add_person, remove_person, get_people_in, get_logs
from utils import save_image
import uuid
import os
import shutil

app = FastAPI()

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

class AddPersonRequest(BaseModel):
    aadhar: int
    name: str

class RemovePersonRequest(BaseModel):
    aadhar: int

@app.post("/addPerson")
def add_person_endpoint(data: AddPersonRequest):
    success = add_person(data.aadhar, data.name)
    if not success:
        raise HTTPException(status_code=400, detail="Could not add person")
    return {"message": "Person added successfully"}

@app.post("/removePerson")
def remove_person_endpoint(data: RemovePersonRequest):
    success = remove_person(data.aadhar)
    if not success:
        raise HTTPException(status_code=404, detail="Person not found")
    return {"message": "Person removed successfully"}

@app.get("/getPeopleIn")
def get_people_in_endpoint():
    return get_people_in()

@app.get("/getLogs")
def get_logs_endpoint():
    return get_logs()

@app.post("/registerUser")
async def register_user(
    file: UploadFile = File(...),
    isDigital: bool = Form(...)
):
    try:
        file_path = save_image(file=file, upload_dir=UPLOAD_DIR)
        aadhar, name = add_person(file=file_path)
        return aadhar
    except Exception as e:
        raise HTTPException(status_code=500, detail="Failed to register user")


    
