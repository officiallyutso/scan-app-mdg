import os
import cv2
from PIL import Image as aadhar_image
import pytesseract as ocr
import time
import Levenshtein
import numpy as np

def parse_digilocker_aadhar_ocr(img) -> dict:

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY)
    cv2.imwrite("processed_aadhar.jpg", thresh)

    image = aadhar_image.open("processed_aadhar.jpg")
    text = ocr.image_to_string(image)

    print("Extracted text: \n", text)

    # Clean and split text
    lines = [line.strip() for line in text.split('\n') if line.strip()]
    
    # Initialize result
    result = {
        "identification_proof": "Aadhar",
        "details": {
            "full_name": "",
            "dob": "",
            "sex": "",
            "aadhar_4_dgts": "",
            "address": "",
            "pin_code": ""
        }
    }
    
    # Extract name (words between AADHAAR and date)
    name_parts = []
    address_parts = []
    capture_address = False
    
    for i, line in enumerate(lines):
        dist = Levenshtein.distance(line, "AADHAAR")
        if dist < 7:
            # Collect name parts until we hit a date
            j = i + 1
            while j < len(lines) and not lines[j].replace("-", "").isdigit():
                name_parts.append(lines[j])
                j += 1
                
        if "Address:" in line:
            capture_address = True
            continue
            
        if capture_address:
            # Stop at PIN code (6 digits)
            if line.strip().isdigit() and len(line.strip()) == 6:
                result["details"]["pin_code"] = line.strip()
                capture_address = False
            else:
                address_parts.append(line)
                
        # Extract gender
        if line.strip() in ["Male", "Female"]:
            result["details"]["sex"] = line.strip()
            
        # Extract DOB (YYYY-MM-DD format)
        if "-" in line and len(line.split("-")) == 3 and all(part.isdigit() for part in line.split("-")):
            result["details"]["dob"] = line.strip()
            
        # Extract last 4 digits of Aadhar
        if "xxxx" in line.lower():
            digits = ''.join(filter(str.isdigit, line))
            if len(digits) >= 4:
                result["details"]["aadhar_4_dgts"] = digits[-4:]
    
    result["details"]["full_name"] = " ".join(name_parts)
    result["details"]["address"] = ", ".join(address_parts)

    # Clean address and extract PIN
    address = result["details"]["address"]
    
    # Remove common OCR artifacts
    artifacts = [
        "Powered by",
        "DigiLocker",
        "Tap to Zoom",
        "Powered by UIDAI",
        "To verify",
        "T",
        "IMYR",
        "AN",
        "uga™"
    ]
    
    for artifact in artifacts:
        address = address.replace(artifact, "")
    
    # Extract PIN from address if present and PIN is empty
    if result["details"]["pin_code"] == "":
        # Check for 6-digit number in address
        words = address.split()

        for word in words:
            if word[-1]==',':
                word = word[:-1]

            if word.isdigit() and len(word) == 6:
                result["details"]["pin_code"] = word
                address = address.replace(word, "")
    
    # Clean up multiple commas and spaces
    address = ", ".join(part.strip() for part in address.split(",") if part.strip())
    result["details"]["address"] = address
    
    return result

def parse_aadhar_card_ocr(img):

    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    mask = cv2.inRange(hsv, np.array([0, 0, 0]), np.array([180, 255, 100])); 
    # result = cv2.bitwise_and(img, img, mask=mask)
    result = np.where(mask[..., None] == 0, [255, 255, 255], img)

    # cv2.imwrite("processed_aadhar.jpg", thresh)
    cv2.imwrite("processed_aadhar.jpg", result)

    # extract text from the processed image. pytesseract is a robust open-source OCR engine.
    image = aadhar_image.open("processed_aadhar.jpg")
    data = ocr.image_to_data(image, output_type=ocr.Output.DICT)

    threshold = 50  # minimum confidence
    filtered_text = []

    for i in range(len(data['text'])):
        if int(data['conf'][i]) > threshold and data['text'][i].strip():
            filtered_text.append(data['text'][i])

    ocr_text = ' '.join(filtered_text)

    print("Extracted text: \n", ocr_text)

    # Helper functions
    def is_date(text):
        # Check for DD/MM/YYYY format
        import re
        date_pattern = r'\d{2}/\d{2}/\d{4}'
        return re.search(date_pattern, text)

    def is_gender(text):
        return text.strip().lower() in ['male', 'female']

    def is_aadhaar_number(text):
        # Remove all spaces and check if it's 12 digits
        print(f"Checking Aadhaar number: {text}")
        digits = ''.join(text)
        print(f"Digits: {digits}")
        return len(digits) == 12 and digits.isdigit()
    
    def find_name_end_index(words):
        for i, word in enumerate(words):
            # Stop at first word containing special chars or matching other fields
            if (any(not c.isalpha() and not c.isspace() for c in word) or
                is_date(word) or
                is_gender(word) or
                is_aadhaar_number(words[i:i+3])):
                return i
        return len(words)

    # Clean and split text
    cleaned_text = ''.join(char if char.isalnum() or char.isspace() or char == '/' else ' ' for char in ocr_text)
    words = cleaned_text.split()

    # Initialize result dictionary
    result = {
        "identification_proof": "Aadhar",
        "details": {
            "full_name": "",
            "dob": "",
            "sex": "",
            "aadhar_number": ""
        }
    }

    # Find components
    name_parts = []
    for i, word in enumerate(words):
        if is_date(word):
            result["details"]["dob"] = word
        elif is_gender(word):
            result["details"]["sex"] = word.capitalize()
        elif is_aadhaar_number(words[i:i+3]):
            # Format Aadhaar number with spaces
            # digits = ','.join(filter(str.isdigit, word))
            digits = ''.join(words[i:i+3])
            result["details"]["aadhar_number"] = digits
        else:
            # If word contains alphabets, consider it part of name
            if any(c.isalpha() for c in word):
                name_parts.append(word)

    # Set name (first occurrence of consecutive words before other fields)
    # result["details"]["full_name"] = ' '.join(name_parts[:2])  # Assuming first two words are name
    name_end = find_name_end_index(words)
    result["details"]["full_name"] = ' '.join(name_parts[:name_end])

    return result

def ocr_aadhaar(path: str, isDigital: bool):
    print("inside ocr_aadhaar")
    start = time.time()

    img = cv2.imread(path)

    if isDigital:
        result = parse_digilocker_aadhar_ocr(img)
    else:
        result = parse_aadhar_card_ocr(img)

    # os.remove("processed_aadhar.jpg")

    end = time.time()

    print(f"Time taken for OCR and parsing is: {end - start:.4f} seconds\n")
    print(f"Parsed result: \n{result}")

    return result