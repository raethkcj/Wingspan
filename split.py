from PIL import Image
import glob, os

os.makedirs("cropped", exist_ok=True)

i = 1
for infile in glob.glob("*.png"):
    with Image.open(infile) as im:
        card1 = im.crop((0,   0, 515,        517))
        card2 = im.crop((562, 0, 562  + 515, 517))
        card3 = im.crop((1123,   0, 1123 + 515, 517))
        card1.save("cropped/" + str(i) + ".png", "PNG")
        i += 1
        card2.save("cropped/" + str(i) + ".png", "PNG")
        i += 1
        card3.save("cropped/" + str(i) + ".png", "PNG")
        i += 1
