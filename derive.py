import pandas as pd
import numpy as np
import math
import matplotlib.pyplot as plt
from scipy.signal import butter, filtfilt
from scipy.optimize import curve_fit
from scipy.differentiate import derivative
import sympy as sp

df = pd.read_csv("C:/Users/ajsau/Documents/formula/corneringSim/cornering-simulation/LCO_ordered_normal_force.csv")

#step 1 - get nominal force
weight = 450 #lbs
mass = weight / 2.205
print(mass)
fz0 = mass * 9.81

#STEP 3 - stiffness parameters
#example data:
x = np.array([.9810, 1.9620, 2.9430])
y = np.array([-20.6, -37.4, -49.5])
print(f"x: {x}")
print(f"y: {y}")
x_wahoo = np.linspace(0,9,9000)

#get the max vertical load using a polynomial
# calculate the polynomial trend line (degree 2)
def exponential(x, r, k, y0):
    return (r * np.exp(-k * (x)) - y0)
    #y = a * np.exp(b * x) + c - suggested by google ai
def logarithmic(x, r, y0):
    return (-r * np.log(x) - y0)
#need L, h
def sigmoidMinus1(x, L, k, h):
    return (-L / (1 + np.exp(-k * (x)))) + h
popt, pcov = curve_fit(sigmoidMinus1, x, y, p0=(10,1,1))
print(popt)

x_symbol, r_symbol, k_symbol, y_symbol, = sp.symbols('x r k y')
eqn_exponential = popt[0] / (x ** 2) + popt[1]
exponential_deriv = sp.diff(eqn_exponential, x_symbol)
sigmoid_eqn = (-popt[0] / (1 + sp.exp(-popt[1] * (x_symbol)))) + popt[2]
print(f"sigmoid_eqn: {sigmoid_eqn}")
limit = float(sp.limit(sigmoid_eqn, x_symbol, float('inf')))
print(f"Horizontal asymptote: y = {limit}")
x_limit = (np.log(((-popt[0])/((limit+1)-popt[2]))-1))/-popt[1]
print(f"x_limit: {x_limit}")

plt.plot(x_wahoo, sigmoidMinus1(x_wahoo, *popt), 'r-')
plt.scatter(x, y)
plt.xlim(0, 20)
plt.ylim(-100, 0)
plt.show()