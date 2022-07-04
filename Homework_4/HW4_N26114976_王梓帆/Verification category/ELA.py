import cv2
import numpy as np

# read image_resized by openCV
image_gray = cv2.imread('image.jpg', cv2.IMREAD_GRAYSCALE)
# resize the image_resized to 32*31
image_resized = cv2.resize(image_gray, (32, 31), interpolation=cv2.INTER_AREA)
# open files to save data
golden_dat = open("./golden.dat", "w")
img_dat = open("./img.dat", "w")
# image size = 32*31
for height in range(31):
    for width in range(32):
        # reset the value of interpolated pixel all the time
        inter_pixel = 0
        # even lines
        if height % 2 == 1:
            # For Left and right boundaries
            if width == 0 or width == 31:
                inter_pixel = int(image_resized[height-1][width]) + int(image_resized[height+1][width])
            else:
                # Calculate D1, D2 and D3
                D1 = abs(int(image_resized[height-1][width-1]) - int(image_resized[height+1][width+1]))
                D2 = abs(int(image_resized[height-1][width])   - int(image_resized[height+1][width]))
                D3 = abs(int(image_resized[height-1][width+1]) - int(image_resized[height+1][width-1]))
                # Compare the value from D1 to D3
                if D2 <= D1 and D2 <= D3:
                    inter_pixel = int(image_resized[height-1][width])   + int(image_resized[height+1][width])
                elif D1 <= D2 and D1 <= D3:
                    inter_pixel = int(image_resized[height-1][width-1]) + int(image_resized[height+1][width+1])
                else:
                    inter_pixel = int(image_resized[height-1][width+1]) + int(image_resized[height+1][width-1])
            # After choosing direction, divide the value of interpolated pixel by two
            inter_pixel = inter_pixel >> 1
        # odd lines
        else:
            inter_pixel = image_resized[height][width]
        # transform to Hexadecimal
        pixel_hex = '{:2x}'.format(inter_pixel)
        # Split those values
        if pixel_hex[0] == ' ':
            pixel_hex = pixel_hex.split()
            pixel_hex = f"0{pixel_hex[0]}"
        # Golden data save all the pixels
        golden_dat.write(pixel_hex + '\n')
        # image data only save pixels in odd lines
        if height % 2 == 0:
            img_dat.write(pixel_hex + '\n')
            
golden_dat.close()
img_dat.close()

