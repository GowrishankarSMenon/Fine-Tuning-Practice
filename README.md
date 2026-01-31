# 🐱🐶 Cats vs Dogs Image Classifier

A deep learning project that classifies images as either cats or dogs using transfer learning with MobileNetV2. Built with TensorFlow and Keras, this classifier achieves high accuracy through fine-tuning a pre-trained model on the Kaggle Cats and Dogs dataset.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Dataset](#dataset)
- [Model Architecture](#model-architecture)
- [Usage](#usage)
- [Results](#results)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Future Improvements](#future-improvements)
- [License](#license)

## 🎯 Overview

This project implements a binary image classification model to distinguish between cats and dogs. It uses transfer learning with MobileNetV2 as the base model, which has been pre-trained on ImageNet. The model is fine-tuned on a dataset of cat and dog images to achieve accurate predictions.

**Key Highlights:**
- Transfer learning with MobileNetV2
- Data augmentation for better generalization
- 80-20 train-validation split
- Binary classification with sigmoid activation
- Real-time image predictions with confidence scores

## ✨ Features

- **Transfer Learning**: Uses MobileNetV2 pre-trained on ImageNet
- **Data Augmentation**: Rotation, flipping, zooming, and shifting for robust training
- **Automatic Data Cleaning**: Removes corrupted images before training
- **Visualization**: Training history plots and prediction results
- **Model Persistence**: Save and load trained models
- **Easy Prediction**: Test on custom images with confidence scores

## 🔧 Requirements

- Python 3.7+
- TensorFlow 2.x
- Keras
- NumPy
- Matplotlib
- Pillow (PIL)

## 📦 Installation

### Google Colab (Recommended)

1. Open a new Google Colab notebook
2. Run the installation cell:

```python
!pip install tensorflow keras
```

### Local Installation

```bash
# Create a virtual environment (optional but recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install tensorflow keras numpy matplotlib pillow
```

## 📊 Dataset

The project uses the Microsoft Cats and Dogs dataset, which contains approximately 25,000 images of cats and dogs.

**Dataset Details:**
- **Source**: Microsoft Download Center
- **Total Images**: ~25,000
- **Classes**: 2 (Cats and Dogs)
- **Split**: 80% training, 20% validation
- **Image Size**: Resized to 160x160 pixels

The dataset is automatically downloaded and organized during setup.

## 🏗️ Model Architecture

### Base Model: MobileNetV2
- Pre-trained on ImageNet
- Input shape: 160x160x3
- Frozen layers (transfer learning)

### Custom Layers
```
Input (160x160x3)
    ↓
MobileNetV2 (frozen)
    ↓
GlobalAveragePooling2D
    ↓
Dense (128 units, ReLU)
    ↓
Dense (1 unit, Sigmoid)
    ↓
Output (Cat: 0-0.5, Dog: 0.5-1)
```

### Training Configuration
- **Optimizer**: Adam (learning rate: 0.0001)
- **Loss Function**: Binary Crossentropy
- **Metrics**: Accuracy
- **Batch Size**: 32
- **Epochs**: 5 (adjustable)

## 🚀 Usage

### Complete Workflow in Google Colab

#### Step 1: Install Dependencies
```python
!pip install tensorflow keras
```

#### Step 2: Import Libraries
```python
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D
from tensorflow.keras.models import Model
import urllib.request
import zipfile
import os
import shutil

print(f"TensorFlow version: {tf.__version__}")
```

#### Step 3: Download Dataset
```python
url = "https://download.microsoft.com/download/3/E/1/3E1C3F21-ECDB-4869-8368-6DEBA77B919F/kagglecatsanddogs_5340.zip"
zip_path = "cats_and_dogs.zip"

print("Downloading dataset...")
urllib.request.urlretrieve(url, zip_path)

print("Extracting dataset...")
with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall('.')

print("Download complete!")
```

#### Step 4: Organize Dataset
```python
os.makedirs('cats_and_dogs_filtered/train/cats', exist_ok=True)
os.makedirs('cats_and_dogs_filtered/train/dogs', exist_ok=True)
os.makedirs('cats_and_dogs_filtered/validation/cats', exist_ok=True)
os.makedirs('cats_and_dogs_filtered/validation/dogs', exist_ok=True)

for animal in ['Cat', 'Dog']:
    source_dir = f'PetImages/{animal}'
    if os.path.exists(source_dir):
        files = [f for f in os.listdir(source_dir) if f.endswith('.jpg')]
        split_idx = int(len(files) * 0.8)
        
        for file in files[:split_idx]:
            src = os.path.join(source_dir, file)
            dst = f'cats_and_dogs_filtered/train/{animal.lower()}s/{file}'
            try:
                shutil.copy(src, dst)
            except:
                pass
        
        for file in files[split_idx:]:
            src = os.path.join(source_dir, file)
            dst = f'cats_and_dogs_filtered/validation/{animal.lower()}s/{file}'
            try:
                shutil.copy(src, dst)
            except:
                pass

print("Dataset organized!")
```

#### Step 5: Clean Corrupted Images
```python
from PIL import Image

def remove_corrupted_images(directory):
    removed_count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(('.jpg', '.jpeg', '.png')):
                filepath = os.path.join(root, file)
                try:
                    img = Image.open(filepath)
                    img.verify()
                    img.close()
                    img = Image.open(filepath)
                    img.load()
                    img.close()
                except:
                    print(f"Removing: {filepath}")
                    os.remove(filepath)
                    removed_count += 1
    return removed_count

print("Cleaning corrupted images...")
train_removed = remove_corrupted_images('cats_and_dogs_filtered/train')
val_removed = remove_corrupted_images('cats_and_dogs_filtered/validation')
print(f"Removed {train_removed + val_removed} corrupted images")
```

#### Step 6: Create Data Generators
```python
IMG_SIZE = (160, 160)
BATCH_SIZE = 32

train_gen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    horizontal_flip=True,
    zoom_range=0.2
)

val_gen = ImageDataGenerator(rescale=1./255)

train_data = train_gen.flow_from_directory(
    'cats_and_dogs_filtered/train',
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary'
)

val_data = val_gen.flow_from_directory(
    'cats_and_dogs_filtered/validation',
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary'
)
```

#### Step 7: Build Model
```python
base_model = MobileNetV2(
    input_shape=(160, 160, 3),
    include_top=False,
    weights='imagenet'
)
base_model.trainable = False

x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dense(128, activation='relu')(x)
output = Dense(1, activation='sigmoid')(x)

model = Model(inputs=base_model.input, outputs=output)

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
    loss='binary_crossentropy',
    metrics=['accuracy']
)
```

#### Step 8: Train Model
```python
history = model.fit(
    train_data,
    validation_data=val_data,
    epochs=5
)
```

#### Step 9: Visualize Results
```python
import matplotlib.pyplot as plt

plt.figure(figsize=(12, 4))

plt.subplot(1, 2, 1)
plt.plot(history.history['accuracy'], label='Training')
plt.plot(history.history['val_accuracy'], label='Validation')
plt.title('Model Accuracy')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.legend()
plt.grid(True)

plt.subplot(1, 2, 2)
plt.plot(history.history['loss'], label='Training')
plt.plot(history.history['val_loss'], label='Validation')
plt.title('Model Loss')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()
plt.grid(True)

plt.show()
```

#### Step 10: Make Predictions
```python
import numpy as np
from tensorflow.keras.preprocessing import image
import random

val_cats_dir = "cats_and_dogs_filtered/validation/cats"
val_dogs_dir = "cats_and_dogs_filtered/validation/dogs"

cat_images = [os.path.join(val_cats_dir, f) for f in os.listdir(val_cats_dir) if f.endswith('.jpg')]
dog_images = [os.path.join(val_dogs_dir, f) for f in os.listdir(val_dogs_dir) if f.endswith('.jpg')]

test_images = random.sample(cat_images, 3) + random.sample(dog_images, 3)
true_labels = ["Cat"] * 3 + ["Dog"] * 3

combined = list(zip(test_images, true_labels))
random.shuffle(combined)
test_images, true_labels = zip(*combined)

fig, axes = plt.subplots(2, 3, figsize=(15, 10))
axes = axes.ravel()

for idx, (img_path, true_label) in enumerate(zip(test_images, true_labels)):
    img = image.load_img(img_path, target_size=IMG_SIZE)
    img_array = image.img_to_array(img) / 255.0
    img_array = np.expand_dims(img_array, axis=0)
    
    prediction = model.predict(img_array, verbose=0)
    
    if prediction[0][0] > 0.5:
        predicted_label = "Dog"
        confidence = prediction[0][0]
    else:
        predicted_label = "Cat"
        confidence = 1 - prediction[0][0]
    
    axes[idx].imshow(image.load_img(img_path))
    axes[idx].axis('off')
    
    is_correct = "✓" if predicted_label == true_label else "✗"
    color = 'green' if predicted_label == true_label else 'red'
    axes[idx].set_title(f'{is_correct} {predicted_label} ({confidence:.1%})\nActual: {true_label}', 
                        color=color, fontsize=12, fontweight='bold')

plt.tight_layout()
plt.show()
```

#### Step 11: Save Model
```python
model.save('cats_dogs_classifier.h5')
print("Model saved successfully!")
```

## 📈 Results

### Expected Performance
- **Training Accuracy**: ~90-95%
- **Validation Accuracy**: ~85-92%
- **Training Time**: ~5-10 minutes (5 epochs on GPU)

### Sample Predictions
The model provides confidence scores for each prediction:
- Cat: 0.0 - 0.5 (closer to 0 = more confident)
- Dog: 0.5 - 1.0 (closer to 1 = more confident)

## 📁 Project Structure

```
cats-vs-dogs-classifier/
│
├── README.md
├── cats_and_dogs_filtered/
│   ├── train/
│   │   ├── cats/
│   │   └── dogs/
│   └── validation/
│       ├── cats/
│       └── dogs/
│
├── cats_dogs_classifier.h5    # Saved model
└── notebooks/
    └── training.ipynb          # Google Colab notebook
```

## 🔍 Troubleshooting

### Common Issues

**1. HTTP Error 403: Forbidden**
- The download URL may have changed
- Use the Microsoft dataset URL provided in the code
- Alternative: Use TensorFlow Datasets

**2. ModuleNotFoundError: No module named 'tensorflow'**
- Run: `!pip install tensorflow keras`
- Restart runtime if needed

**3. UnidentifiedImageError / Corrupted Images**
- Run the image cleaning script (Step 5)
- Some images in the dataset are corrupted by default

**4. Out of Memory Error**
- Reduce `BATCH_SIZE` from 32 to 16 or 8
- Use a smaller model or reduce image size

**5. Low Validation Accuracy**
- Increase training epochs (try 10-15)
- Unfreeze some layers of the base model
- Add more data augmentation

## 🚀 Future Improvements

- [ ] Fine-tune more layers of MobileNetV2
- [ ] Experiment with other architectures (ResNet, EfficientNet)
- [ ] Add class activation maps (CAM) for interpretability
- [ ] Deploy as a web application (Flask/Streamlit)
- [ ] Add multi-class support (different dog/cat breeds)
- [ ] Implement model quantization for edge deployment
- [ ] Create a mobile app version
- [ ] Add confidence threshold tuning

## 📝 Notes

- The model uses binary classification (0 = Cat, 1 = Dog)
- Data augmentation is only applied to training data, not validation
- The base MobileNetV2 layers are frozen to preserve pre-trained weights
- All images are resized to 160x160 pixels for consistency

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## 📜 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- **Dataset**: Microsoft Cats and Dogs Dataset
- **Base Model**: MobileNetV2 from TensorFlow/Keras
- **Framework**: TensorFlow and Keras
- **Platform**: Google Colab for development and training

## 📧 Contact

For questions or feedback, please open an issue on the repository.

---

**Happy Classifying! 🐱🐶**