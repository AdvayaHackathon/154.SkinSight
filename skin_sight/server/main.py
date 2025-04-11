from inference_sdk import InferenceHTTPClient
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import cv2
import numpy as np
import tempfile
from werkzeug.utils import secure_filename

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Roboflow API client
client = InferenceHTTPClient(
    api_url="https://detect.roboflow.com",
    api_key="CbrrMwWgSeByWhFBaz1T"
)

# PASI Scale Constants
BODY_REGIONS = {
    "head": 0.1,    # 10% of total skin
    "upper_limbs": 0.2,  # 20% of total skin
    "trunk": 0.3,   # 30% of total skin
    "lower_limbs": 0.4   # 40% of total skin
}

@app.route('/analyze', methods=['POST'])
def analyze_image():
    """
    Endpoint to analyze skin images for psoriasis detection using AR depth data
    Accepts: image file and depth data in the request
    Returns: JSON with analysis results including PASI score
    """
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    if 'depth_map' not in request.files:
        return jsonify({'error': 'No depth map provided'}), 400
    
    file = request.files['image']
    depth_file = request.files['depth_map']
    
    if file.filename == '' or depth_file.filename == '':
        return jsonify({'error': 'File not selected'}), 400
    
    # Get body region from the request
    body_region = request.form.get('body_region', 'trunk')
    if body_region not in BODY_REGIONS:
        return jsonify({'error': 'Invalid body region'}), 400
    
    # Save the uploaded files to temporary locations
    temp_dir = tempfile.gettempdir()
    
    # Save image
    img_filename = secure_filename(file.filename)
    img_filepath = os.path.join(temp_dir, img_filename)
    file.save(img_filepath)
    
    # Save depth map
    depth_filename = secure_filename(depth_file.filename)
    depth_filepath = os.path.join(temp_dir, depth_filename)
    depth_file.save(depth_filepath)
    
    try:
        # Process the image with Roboflow for detection
        roboflow_result = client.run_workflow(
            workspace_name="skinsight-lpkik",
            workflow_id="custom-workflow",
            images={
                "image": img_filepath
            },
            use_cache=True
        )
        
        # Read the image and depth map for additional processing
        image = cv2.imread(img_filepath)
        depth_map = cv2.imread(depth_filepath, cv2.IMREAD_ANYDEPTH)  # Assuming depth is 16-bit single channel
        
        # Get affected area analysis
        area_results = calculate_area_from_depth(depth_map, roboflow_result)
        
        # Analyze redness (erythema)
        color_results = analyze_redness(image, roboflow_result)
        
        # Calculate PASI scores for this region
        pasi_results = calculate_pasi_score(
            area_results['area_percentage'],
            color_results['erythema_score'],
            body_region,
            roboflow_result
        )
        
        # Combine all results
        processed_result = {
            'success': True,
            'detection': roboflow_result,
            'area_analysis': area_results,
            'color_analysis': color_results,
            'pasi_assessment': pasi_results,
            'diagnosis': get_diagnosis(pasi_results['pasi_score'])
        }
        
        return jsonify(processed_result)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
    finally:
        # Clean up the temporary files
        if os.path.exists(img_filepath):
            os.remove(img_filepath)
        if os.path.exists(depth_filepath):
            os.remove(depth_filepath)

def calculate_area_from_depth(depth_map, detection_result):
    """
    Calculate the affected area using AR depth data
    """
    try:
        # Get the total pixels in the image
        total_pixels = depth_map.shape[0] * depth_map.shape[1]
        
        # Extract the affected regions from Roboflow detection
        affected_pixels = 0
        lesion_depths = []
        
        if 'predictions' in detection_result and len(detection_result['predictions']) > 0:
            for pred in detection_result['predictions']:
                if 'class' in pred and pred['class'] == 'psoriasis':
                    # Extract bounding box coordinates
                    x = int(pred['x'])
                    y = int(pred['y'])
                    width = int(pred['width'])
                    height = int(pred['height'])
                    
                    # Calculate area based on coordinates
                    # Ensure we don't go out of bounds
                    x_min = max(0, x - width//2)
                    x_max = min(depth_map.shape[1], x + width//2)
                    y_min = max(0, y - height//2)
                    y_max = min(depth_map.shape[0], y + height//2)
                    
                    # Count pixels in this region
                    region_pixels = (x_max - x_min) * (y_max - y_min)
                    affected_pixels += region_pixels
                    
                    # Extract depth information for this region (for elevation analysis)
                    region_depth = depth_map[y_min:y_max, x_min:x_max]
                    avg_depth = np.mean(region_depth) if region_depth.size > 0 else 0
                    lesion_depths.append({
                        'region': f"x:{x},y:{y},w:{width},h:{height}",
                        'avg_depth': float(avg_depth),
                        'area_pixels': region_pixels
                    })
        
        # Calculate area percentage
        area_percentage = (affected_pixels / total_pixels) * 100 if total_pixels > 0 else 0
        
        # Convert area percentage to PASI area score (0-6)
        area_score = 0
        if area_percentage > 0 and area_percentage < 10:
            area_score = 1
        elif area_percentage >= 10 and area_percentage < 30:
            area_score = 2
        elif area_percentage >= 30 and area_percentage < 50:
            area_score = 3
        elif area_percentage >= 50 and area_percentage < 70:
            area_score = 4
        elif area_percentage >= 70 and area_percentage < 90:
            area_score = 5
        elif area_percentage >= 90:
            area_score = 6
        
        return {
            'affected_pixels': affected_pixels,
            'total_pixels': total_pixels,
            'area_percentage': area_percentage,
            'area_score': area_score,
            'lesion_details': lesion_depths
        }
    except Exception as e:
        return {
            'error': str(e),
            'affected_pixels': 0,
            'total_pixels': 0,
            'area_percentage': 0,
            'area_score': 0
        }

def analyze_redness(image, detection_result):
    """
    Analyze the redness (erythema) in affected areas
    Returns severity score (0-4) for erythema based on color analysis
    """
    try:
        # Convert image to HSV for better color analysis
        hsv_image = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        
        # Track redness metrics
        total_regions = 0
        total_redness = 0
        redness_details = []
        
        if 'predictions' in detection_result and len(detection_result['predictions']) > 0:
            for pred in detection_result['predictions']:
                if 'class' in pred and pred['class'] == 'psoriasis':
                    # Extract bounding box coordinates
                    x = int(pred['x'])
                    y = int(pred['y'])
                    width = int(pred['width'])
                    height = int(pred['height'])
                    
                    # Ensure we don't go out of bounds
                    x_min = max(0, x - width//2)
                    x_max = min(image.shape[1], x + width//2)
                    y_min = max(0, y - height//2)
                    y_max = min(image.shape[0], y + height//2)
                    
                    # Extract the region
                    region = hsv_image[y_min:y_max, x_min:x_max]
                    
                    if region.size > 0:
                        # Analyze redness in HSV space
                        # Hue for redness is approximately 0-10 and 170-180
                        # Create mask for red hues
                        lower_red1 = np.array([0, 50, 50])
                        upper_red1 = np.array([10, 255, 255])
                        mask1 = cv2.inRange(region, lower_red1, upper_red1)
                        
                        lower_red2 = np.array([170, 50, 50])
                        upper_red2 = np.array([180, 255, 255])
                        mask2 = cv2.inRange(region, lower_red2, upper_red2)
                        
                        red_mask = mask1 + mask2
                        
                        # Calculate percentage of pixels that are red
                        red_pixels = np.sum(red_mask > 0)
                        total_pixels = region.shape[0] * region.shape[1]
                        red_percentage = (red_pixels / total_pixels) * 100 if total_pixels > 0 else 0
                        
                        # Calculate average saturation of red pixels (intensity of redness)
                        red_intensity = np.mean(region[red_mask > 0, 1]) if red_pixels > 0 else 0
                        
                        # Track metrics
                        total_regions += 1
                        total_redness += red_percentage
                        
                        redness_details.append({
                            'region': f"x:{x},y:{y},w:{width},h:{height}",
                            'red_percentage': float(red_percentage),
                            'red_intensity': float(red_intensity)
                        })
        
        # Calculate average redness percentage
        avg_redness = total_redness / total_regions if total_regions > 0 else 0
        
        # Convert to PASI erythema score (0-4)
        erythema_score = 0
        if avg_redness > 0 and avg_redness < 20:
            erythema_score = 1  # Slight
        elif avg_redness >= 20 and avg_redness < 40:
            erythema_score = 2  # Moderate
        elif avg_redness >= 40 and avg_redness < 60:
            erythema_score = 3  # Severe
        elif avg_redness >= 60:
            erythema_score = 4  # Very severe
        
        return {
            'average_redness_percentage': avg_redness,
            'erythema_score': erythema_score,
            'redness_details': redness_details
        }
    except Exception as e:
        return {
            'error': str(e),
            'average_redness_percentage': 0,
            'erythema_score': 0,
            'redness_details': []
        }

def calculate_pasi_score(area_percentage, erythema_score, body_region, detection_result):
    """
    Calculate PASI score components
    Uses information from detection and color analysis
    """
    # Calculate area score (0-6) based on percentage affected
    area_score = 0
    if area_percentage > 0 and area_percentage < 10:
        area_score = 1
    elif area_percentage >= 10 and area_percentage < 30:
        area_score = 2
    elif area_percentage >= 30 and area_percentage < 50:
        area_score = 3
    elif area_percentage >= 50 and area_percentage < 70:
        area_score = 4
    elif area_percentage >= 70 and area_percentage < 90:
        area_score = 5
    elif area_percentage >= 90:
        area_score = 6
    
    # Estimate induration (thickness) score based on confidence
    # This is an approximation - in a real system you would use depth data
    induration_score = 0
    if 'predictions' in detection_result and len(detection_result['predictions']) > 0:
        confidences = [pred.get('confidence', 0) for pred in detection_result['predictions'] 
                      if pred.get('class') == 'psoriasis']
        avg_confidence = sum(confidences) / len(confidences) if confidences else 0
        
        # Convert confidence to induration score (0-4)
        if avg_confidence > 0 and avg_confidence < 0.3:
            induration_score = 1  # Slight
        elif avg_confidence >= 0.3 and avg_confidence < 0.6:
            induration_score = 2  # Moderate
        elif avg_confidence >= 0.6 and avg_confidence < 0.85:
            induration_score = 3  # Severe
        elif avg_confidence >= 0.85:
            induration_score = 4  # Very severe
    
    # Estimate desquamation (scaling) score
    # In a real system, this would require texture analysis
    # Here we'll approximate based on detection confidence
    desquamation_score = max(0, min(4, int(induration_score * 0.8)))
    
    # Calculate the PASI score for this region
    region_weight = BODY_REGIONS.get(body_region, 0.3)  # Default to trunk if invalid
    severity_sum = erythema_score + induration_score + desquamation_score
    regional_pasi = severity_sum * area_score * region_weight
    
    # For a full PASI score, you would need to analyze all body regions
    # Here we're just calculating for one region
    
    return {
        'body_region': body_region,
        'region_weight': region_weight,
        'area_score': area_score,
        'erythema_score': erythema_score,
        'induration_score': induration_score,
        'desquamation_score': desquamation_score,
        'regional_pasi': regional_pasi,
        'pasi_score': regional_pasi,  # This is just the regional score; full PASI would sum all regions
        'pasi_severity': get_pasi_severity(regional_pasi)
    }

def get_pasi_severity(pasi_score):
    """
    Interpret PASI score severity
    """
    if pasi_score < 3:
        return "Mild"
    elif pasi_score < 10:
        return "Moderate"
    elif pasi_score < 20:
        return "Severe"
    else:
        return "Very Severe"

def get_diagnosis(pasi_score):
    """
    Generate treatment recommendations based on PASI score
    """
    if pasi_score < 3:
        return {
            "severity": "Mild",
            "description": "Mild psoriasis with limited affected area.",
            "recommendations": [
                "Topical corticosteroids (low to medium potency)",
                "Regular moisturizing with emollients",
                "Coal tar products for scalp involvement",
                "Avoid known triggers (stress, certain medications)"
            ]
        }
    elif pasi_score < 10:
        return {
            "severity": "Moderate",
            "description": "Moderate psoriasis with noticeable plaque formation.",
            "recommendations": [
                "Topical corticosteroids (medium to high potency)",
                "Vitamin D analogs (calcipotriene)",
                "Phototherapy (narrow-band UVB)",
                "Consider topical retinoids",
                "Regular moisturizing and stress management"
            ]
        }
    elif pasi_score < 20:
        return {
            "severity": "Severe",
            "description": "Severe psoriasis requiring more aggressive treatment.",
            "recommendations": [
                "Phototherapy (PUVA or narrow-band UVB)",
                "Oral systemic treatments (methotrexate, cyclosporine)",
                "Consider biologic therapies",
                "Combined topical therapy",
                "Consult with dermatologist promptly"
            ]
        }
    else:
        return {
            "severity": "Very Severe",
            "description": "Very severe psoriasis with extensive body coverage.",
            "recommendations": [
                "Biologic therapies (TNF-alpha inhibitors, IL-17 inhibitors)",
                "Systemic immunosuppressants",
                "Close monitoring for comorbidities (psoriatic arthritis, cardiovascular disease)",
                "Immediate dermatologist consultation",
                "Consider hospitalization for severe cases"
            ]
        }

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
    print("Server running on http://localhost:5000")