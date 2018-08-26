
#https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml

#http://machinethink.net/blog/coreml-custom-layers/

#https://apple.github.io/coremltools/generated/coremltools.converters.keras.convert.html#coremltools.converters.keras.convert

# https://stackoverflow.com/questions/44529869/converting-uiimage-to-mlmultiarray-for-keras-model
# When you convert the keras model to MLModel, you need to

# First run `source activate egohands` - something you did in that conda env fixes broken shit with running the coreml tools

import coremltools


###
#if dataset_name == 'fer2013':
#    return {0:'angry',1:'disgust',2:'fear',3:'happy',
#        4:'sad',5:'surprise',6:'neutral'}
#    elif dataset_name == 'imdb':
#        return {0:'woman', 1:'man'}
#elif dataset_name == 'KDEF':
#    return {0:'AN', 1:'DI', 2:'AF', 3:'HA', 4:'SA', 5:'SU', 6:'NE'}
###

##http://machinethink.net/blog/help-core-ml-gives-wrong-output/
#
# Settings based on: https://github.com/oarriaga/face_classification/blob/master/src/utils/preprocessor.py
# Looks to be 48x48 and grayscale, scaled to
#               x = x / 255.0
#               x = x - 0.5
#               x = x * 2.0
#
##

coreml_model = coremltools.converters.keras.convert('/Users/cmathias/chris/ar-dev/spillwave/emotism/Emotism/Emotism/resources/harshsikka/fer2013_big_XCEPTION.54-0.66.hdf5', input_names = 'image', image_input_names = 'image', class_labels = ['angry','disgust','fear','happy','sad','surprise','neutral'], image_scale=2/255.0, gray_bias=-1)
                                                    #input_names = 'data')

print coreml_model

#coremltools.utils.save_spec(coreml_model, '1miohands.mlmodel')
# The above is what is given in samples, but the below works :D
coreml_model.save('harshsikka_big.mlmodel')



#add this line: image_input_names = 'data'
#  which is the magic that makes the expected input CVPixelBuffer that cleanly aligns to the
#  image coming from the camera
