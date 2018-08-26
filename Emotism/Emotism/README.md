#  Emotion Detection + Some Fun Emotion Learning Games

## References


### 1. TalHassner
1st attempt at emotion detection using "state of the art" circa 2015
    https://talhassner.github.io/home/publication/2015_ICMI
    
    This fails only because the model requires:
    1. Transforming the images to grayscale & then lbp
    2. Running through 5 CNN's
    3. Averaging the result
    
    And the CNN's are like 500MB each and we really shouldn't have a 2GB+ app...
    
### 2. harshsikka
MIT License
"The model is fairly good, with emotion classification test accuracy of 66%."
https://modeldepot.io/harshsikka/emotion-classification https://github.com/oarriaga/face_classification

    Advantage here is this is a simple 1-shot CNN pretrained so much lighter on the CPU & download size
    
    fer2018_..*

http://wiki.hawkguide.com/wiki/Swift:_Convert_between_CGImage,_CIImage_and_UIImage


if dataset_name == 'fer2013':
return {0:'angry',1:'disgust',2:'fear',3:'happy',
4:'sad',5:'surprise',6:'neutral'}


## Other Notes
Useful bit for OCR idea:
https://heartbeat.fritz.ai/building-a-camera-calculator-with-vision-and-tesseract-ocr-in-ios-26f16240fe51


