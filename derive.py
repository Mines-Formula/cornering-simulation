import pandas as pd
import numpy as np
import math
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt
from scipy.special import expit
from scipy.optimize import curve_fit
from scipy.differentiate import derivative
import sympy as sp

df = pd.read_csv("C:/Users/ajsau/Documents/formula/corneringSim/cornering-simulation/LCO_ordered_normal_force.csv")

#step 1 - get nominal force
weight = 450 #lbs
mass = weight / 2.205
print(f"mass of the car: {mass}")
fz0 = mass * 9.81

''' wait for payton
#step 2 - friction coefficient paremeter
#dy - cornering force
#pdy1 - friction coefficient
lateral_force = df["LateralForce"]
dy = max(abs(lateral_force))
print(dy)
pdy1 = dy / fz0
'''

#step 3 - stiffness parameters



#step 4 - shape parameter
# Using google AI overview code for butterworth filter
fs = 3000  # Sampling frequency (Hz) high number make thinner
cutoff_freq = 10 # Cutoff frequency (Hz) low number make thinner
nyquist_freq = 0.5 * fs
normalized_cutoff = cutoff_freq / nyquist_freq
order = 4 # Filter order

#create the filter
b, a = butter(order, normalized_cutoff, btype="low")
#run the data through the filter
other_df = pd.read_csv("C:/Users/ajsau/Documents/formula/corneringSim/cornering-simulation/LCO_ordered_slip_angle_and_lateral_force.csv")
sa_filtered = filtfilt(b, a, other_df["SlipAngle"].values)
dy_filtered = filtfilt(b, a, other_df["LateralForce"].values)
plt.plot(sa_filtered, dy_filtered)

#define the sigmoid function - what is the equation to fit
def sigmoid(x, L, x0, k, h):
    return (-L / (1 + np.exp(-k * (x - x0)))) + h
#create constant values for the equation
popt, pcov = curve_fit(sigmoid, sa_filtered, dy_filtered)
#plot it - only the bottom half fits, but that's all we need
plt.plot(sa_filtered, sigmoid(sa_filtered, *popt), 'r-')

#Dy = minimum value
#ya = limit of the graph
x = sp.symbols('x')
eqn = (-popt[0] / (1 + sp.exp(-popt[2] * (x - popt[1])))) + popt[3]
print(f"Equation of sigmoid for finding pcy1: {eqn}")
Ya = float(0 - sp.limit(eqn, x, float('inf')))
Dy = abs(min(other_df["LateralForce"]))

#calculate pcy1 - shape parameter
pcy1 = 1 + (1 - (2/math.pi)*math.asin(Ya/Dy))
print(f"Dy from step 4: {Dy}")
print(f"pcy1: {pcy1}")
lambdaCY = 1
print(f"lamda is {lambdaCY}, so Cy = pcy1*{lambdaCY}")
Cy = pcy1 * lambdaCY
print(f"Cy = {Cy}")


#step 5 pey1
#Dy is probably from step 2?
#Cy and pcy1 is from step 4
#xm is also from step 2 - peak slip angle in radians
#where does slope of fz0 curve come from? - sFz0
#**example data**
pcy1 = 1.5
sFz0 = -73456
Cy = pcy1
Dy = -3050
xm = 0.14
#**end example data**
By = sFz0 / (Cy * Dy)
Bxm = By * xm
pey1 = (Bxm - math.tan(math.pi/(2*pcy1)))/(Bxm - math.atan(Bxm))
print(f"pey1 = {pey1}")


#step 6
#xoffset - get x intercept of step 2 graph
#**example data**
xoffset = 0.5 
#**end example data**
phy1 = xoffset * (math.pi/180)
print(f"Horizontal shift phy1: {phy1}")

#step 7
#yoffset = get y intercept of step 2 graph
#**example data**
yoffset = 40
#**end example data**
pvy1 = yoffset/fz0
print(f"Value of pvy1: {pvy1}")

#step 8
#we get to choose what mass we want to play with i think
massOther = 300
#calculate how friction coefficient varies with load - pdy2
fzOther = massOther*9.81
#fy in kN comes from step 2 graph - max of graph? at 300 kg or some mass
#**example data**
fy = 4.3
pdy1 = 1.55
fz0Example = 1962
#**end example data**
mu = fy / (fzOther/1000) #get into kN DO WE NEED THIS?
deltaFz = fz0Example - fzOther
deltamu = abs(pdy1) - mu
pdy2 = deltamu/deltaFz*fz0Example
print(f"pdy1 value: {pdy2}")

#step 10
#phy2 is from step 9'
#camber is from step 9
#**example data**
phy2 = 0.35
camber = 0.0698
#**end example data**
phy2 = phy2 * (math.pi / 180) #convert to radians
phy3 = (phy2 - phy1) / camber
print(f"phy3 = {phy3}")