#  Emotion Detection + Some Fun Emotion Learning Games

## What Is This?

Working with Spillwave and an Autism consultant, SolipsAR is developing an application that will do a variety of things in 
support of helping Autistic children practice emotion recognition.

This is a Proof-Of-Concept (POC) repository for working through some of the intricancies of face detection and
emotion recognition.  The basic strategy here is to work through some of the available options for pre-trained CNN's that
already do emotion recognition.  The current implementation (#2 below) is accurate to ~60% or so. While this may seem low,
it is common for autistic children to be at 25% accuracy, and the consultants idea is to gameify the emotion detection.

We will also be experimenting with other pre-trained networks and are considering working out our own. 

The main problems we are solving in this repo/POC are:

1. Obtain an emotion detection network
2. Use Apple Vision framework to detect faces
3. Run the detected face through a CNN ported to CoreML
4. Display the detected face and the top prediction

[![Autism Helper](https://img.youtube.com/vi/ELZ4de4FStU/0.jpg)](https://youtu.be/ELZ4de4FStU "Autism Helper")

 
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



