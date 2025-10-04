import pandas as pd
import numpy as np
import math
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt
from scipy.special import expit
from scipy.optimize import curve_fit
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
print(f"pcy1: {pcy1}")

plt.show()