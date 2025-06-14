from PIL import Image

def bmp_to_1bit_coe(bmp_file, coe_file, image_width, image_height, threshold=128):
    img = Image.open(bmp_file).convert("L")  # 转灰度图
    pixels = list(img.getdata())

    total_pixels = image_width * image_height
    if len(pixels) != total_pixels:
        raise ValueError("图像尺寸与宽高参数不符")

    with open(coe_file, 'w') as f_out:
        f_out.write("memory_initialization_radix=2;\n")
        f_out.write("memory_initialization_vector=\n")

        for i, p in enumerate(pixels):
            bit = '1' if p >= threshold else '0'
            f_out.write(bit)
            if i != total_pixels - 1:
                f_out.write(",\n")
            else:
                f_out.write(";\n")

    print(f"[✔] 1bit COE 文件已写入：{coe_file}")

if __name__ == "__main__":
    bmp_filename = "game_over.bmp"
    coe_output = "game_over.coe"
    width = 640
    height = 480
    bmp_to_1bit_coe(bmp_filename, coe_output, width, height)
