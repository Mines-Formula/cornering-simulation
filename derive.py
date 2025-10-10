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
x = np.array([.9810, 1.9620, 2.9430])
y = np.array([-20.6, -37.4, -49.5])

#get the max vertical load using a polynomial
# calculate the polynomial trend line (degree 2)
def exponential(x, r, k, y0):
    return (r * np.exp(-k * (x)) - y0)
    #y = a * np.exp(b * x) + c - suggested by google ai
popt, pcov = curve_fit(exponential, x, y, p0=(10,1,1))
print(popt)
x_wahoo = np.linspace(0,9,9000)

x_symbol, r_symbol, k_symbol, y_symbol, = sp.symbols('x r k y')
eqn_exponential = r_symbol * sp.exp(-k_symbol * x_symbol) - y_symbol
exponential_deriv = sp.diff(eqn_exponential, x_symbol)
print(f"Rate of change at 7.400kN: {exponential_deriv.subs({r_symbol: popt[0], k_symbol: popt[1], y_symbol: popt[2], x_symbol: 7.4}).evalf()}")
print(f"Rate of change at 1.962kN: {exponential_deriv.subs({r_symbol: popt[0], k_symbol: popt[1], y_symbol: popt[2], x_symbol: 1.962}).evalf()}")
print("Value at 7.40kN: " + str(exponential(7.4, *popt)))
plt.plot(x_wahoo, exponential(x_wahoo, *popt), 'r-')
plt.scatter(x, y)
plt.xlim(0, 20)
#plt.show()

#former polynomial
values = np.polyfit(x, y, 2)
eqn = np.poly1d(values)
print(type(eqn))
print(eqn)

#take the derivative
eqn_deriv = eqn.deriv()
print(f"Derivative: {eqn_deriv}")
#find the roots based on the coeff
#root = max value of stiffness (still of type list)
roots = np.roots(eqn_deriv.coeffs)

#degree of two is the closest, but still very far off
max_vertical_load_poly = roots[0]
print(max_vertical_load_poly)
pxy2 = (max_vertical_load_poly/fz0)
#should be 3.77
print(pxy2)

x_wahoo = list(range(0,9000))
plt.plot(x_wahoo, eqn(x_wahoo), color="green")
plt.plot(x_wahoo, eqn_deriv(x_wahoo), color="red")
plt.xlim(0, 9000)
plt.ylim(-90, 10)
plt.show()
