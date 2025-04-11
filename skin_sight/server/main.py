from inference_sdk import InferenceHTTPClient
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import base64
import tempfile
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Roboflow API client
client = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="CbrrMwWgSeByWhFBaz1T"
)

@app.route('/analyze', methods=['POST'])
def analyze_image():
    """
    Endpoint to analyze skin images for psoriasis detection
    Accepts: image file in the request
    Returns: JSON with analysis results
    """
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No image selected'}), 400
    
    # Save the uploaded file to a temporary location
    temp_dir = tempfile.gettempdir()
    filename = secure_filename(file.filename)
    filepath = os.path.join(temp_dir, filename)
    file.save(filepath)
    
    try:
        # Process the image with Roboflow
        result = client.run_workflow(
            workspace_name="skinsight-lpkik",
            workflow_id="custom-workflow",
            images={
                "image": filepath
            },
            use_cache=True  # cache workflow definition for 15 minutes
        )
        
        # Extract relevant information from the result
        processed_result = {
            'success': True,
            'prediction': result,
            'severity': calculate_severity(result),
            'diagnosis': get_diagnosis(result)
        }
        
        return jsonify(processed_result)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
    finally:
        # Clean up the temporary file
        if os.path.exists(filepath):
            os.remove(filepath)

def calculate_severity(result):
    """
    Calculate severity based on Roboflow results
    Returns: severity level (mild, moderate, severe)
    """
    # This is a placeholder implementation - customize based on your model's output
    try:
        # Example logic - adjust based on your actual model output structure
        if 'predictions' in result and len(result['predictions']) > 0:
            # Get average confidence of detected areas
            confidences = [pred.get('confidence', 0) for pred in result['predictions']]
            avg_confidence = sum(confidences) / len(confidences) if confidences else 0
            
            # Get total area of detected regions
            total_area = 0
            for pred in result['predictions']:
                if 'width' in pred and 'height' in pred:
                    total_area += pred['width'] * pred['height']
            
            # Determine severity based on confidence and area
            if avg_confidence > 0.8 and total_area > 10000:
                return "severe"
            elif avg_confidence > 0.6 or total_area > 5000:
                return "moderate"
            else:
                return "mild"
        return "undetermined"
    except:
        return "undetermined"

def get_diagnosis(result):
    """
    Generate a diagnosis based on Roboflow results
    Returns: diagnosis text
    """
    # This is a placeholder implementation - customize based on your model's output
    try:
        if 'predictions' in result and len(result['predictions']) > 0:
            # Count detections by class
            classes = {}
            for pred in result['predictions']:
                class_name = pred.get('class', 'unknown')
                if class_name in classes:
                    classes[class_name] += 1
                else:
                    classes[class_name] = 1
            
            # Generate diagnosis based on detected classes
            if 'psoriasis' in classes:
                return "Psoriasis detected. Recommend topical corticosteroids and regular moisturizing."
            elif 'eczema' in classes:
                return "Eczema detected. Recommend avoiding irritants and using prescribed creams."
            else:
                return "No specific skin condition detected. Recommend general skin care."
        return "No clear diagnosis available from the image."
    except:
        return "Unable to generate diagnosis from analysis."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
    print("Server running on http://localhost:5000")
