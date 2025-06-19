import os

alpha = "abcdefjhijklmnopqrstuvwxyz"
for letter in alpha:
    try:
        os.rename("{}.jpg".format(letter), "{}.png".format(letter))
    except FileNotFoundError:
        continue