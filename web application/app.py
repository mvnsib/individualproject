from flask import Flask, request, render_template
from flask_cors import CORS
from torchvision import datasets, models, transforms
from PIL import Image
import pickle
import torch



#Load HTML template for the frontend
app = Flask(__name__, template_folder="app/templates")
cors = CORS(app) #Request will get blocked otherwise on Localhost
#Load the exported model 
model = pickle.load(open("app/model.pkl", "rb"))

#Classes that are defined for the model to output
label_classes = ['D', 'P', 'S', 'V']
#Dictionary was used to output the following values on the web app
label_dict = {
    "D" : "Diabetic Foot Ulcer",
    "P" : "Preassure Ulcer",
    "S" : "Surgical Wound",
    "V" : "Venous Leg Ulcer"
}


#First app route where the template is rendered
@app.route("/")
def index():
    return render_template("index.html")

# GET and POST HTTP Request which will send the user to this directory
@app.route('/predict', methods=['GET', 'POST'])
def predict():
    #Checks for the POST method
    if request.method == 'POST':
        #Data means and standard deviation for the preprocessing
        data_means = [0.485, 0.456, 0.406]
        data_stds = [0.229, 0.224, 0.225]
        #Uploaded file
        img = request.files['file']
        #Double checks if the image ends with a jpg or jpeg, because the model was not trained with png images
        if img.filename.endswith('.jpg') or img.filename.endswith('.jpeg'): 
            #opens the image
            pilimg = Image.open(img)
            #model evaluation
            model.eval()
            with torch.no_grad():
                #Transforming the image to tensor for the model to read
                transform = transforms.Compose([
                    transforms.Resize((240,240)),
                    transforms.ToTensor(),
                    transforms.Normalize(data_means, data_stds)])
                trans_img = transform(pilimg)
                #unsqueeze function outputs the model label
                model_label  = model(trans_img.unsqueeze(0))
                output_softmax = torch.log_softmax(model_label.data, dim = 1)
                _, preds = torch.max(output_softmax, dim = 1)
                #uses the model label for the dictionary 
                label = label_classes[preds]
                label_output = label_dict.get(label)
        #if user enters the wrong format this is the output
        else:
            return render_template("index.html", result = "wrong format")
    
        return render_template("index.html", result = label_output)
    return render_template("index.html")
    
#runs the web application
if __name__=='__main__':
    app.run(port = 5000, host="0.0.0.0")


