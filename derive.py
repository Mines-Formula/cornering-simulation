import pandas as pd
import numpy as np
import math
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt

df = pd.read_csv("C:/Users/ajsau/Documents/formula/corneringSim/cornering-simulation/LCO_ordered_normal_force.csv")

#step 1 - get nominal force
weight = 450 #lbs
mass = weight / 2.205
print(mass)
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

#STEP 3 - stiffness parameters
#example data:
x = np.array([100*9.81, 200*9.81, 300*9.81])
y = np.array([-20.6, -37.4, -49.5])

# Calculate the polynomial trend line (degree 2)
values = np.polyfit(x, y, 2)
eqn = np.poly1d(values)
print(eqn)

#take the derivative
eqn_deriv = eqn.deriv()
print(f"Derivative: {eqn_deriv}")
#find the roots based on the coeff
#root = max value of stiffness (still of type list)
root = np.roots(eqn_deriv.coeffs)
print(root)

'''
#step 4 - shape parameter
# Using google AI overview code for butterworth filter
fs = 1000  # Sampling frequency (Hz)
cutoff_freq = 50 # Cutoff frequency (Hz)
nyquist_freq = 0.5 * fs
normalized_cutoff = cutoff_freq / nyquist_freq
order = 4 # Filter order

b, a = butter(order, normalized_cutoff, btype="low")
# Assuming 'data_series' is your Pandas Series
other_df = pd.read_csv("C:/Users/ajsau/Documents/formula/corneringSim/cornering-simulation/LCO_ordered_slip_angle_and_lateral_force.csv")
sa_filtered = filtfilt(b, a, other_df["SlipAngle"].values)
dy_filtered = filtfilt(b, a, other_df["LateralForce"].values)
plt.plot(sa_filtered, dy_filtered)
plt.show()


print(sa.head())
print(fz0.head())
plt.plot(sa, fz0)
plt.show()
'''