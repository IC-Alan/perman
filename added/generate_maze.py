import random
import numpy as np

# VGA 配置
WIDTH = 64
HEIGHT = 48
CELL_SIZE = 10

# 居中迷宫配置
MAZE_W = 32
MAZE_H = 24
OFFSET_X = (WIDTH - MAZE_W) // 2
OFFSET_Y = (HEIGHT - MAZE_H) // 2

# DFS生成迷宫
def dfs_maze(w, h):
    maze = np.ones((h, w), dtype=int)
    visited = np.zeros((h, w), dtype=bool)

    def inside(x, y):
        return 0 <= x < w and 0 <= y < h

    def neighbors(x, y):
        d = [(0, -2), (0, 2), (-2, 0), (2, 0)]
        random.shuffle(d)
        for dx, dy in d:
            nx, ny = x + dx, y + dy
            if inside(nx, ny) and not visited[ny][nx]:
                yield (nx, ny, dx, dy)

    def carve(x, y):
        visited[y][x] = True
        maze[y][x] = 0
        for nx, ny, dx, dy in neighbors(x, y):
            if not visited[ny][nx]:
                maze[y + dy // 2][x + dx // 2] = 0
                carve(nx, ny)

    start_x = random.randrange(1, w, 2)
    start_y = random.randrange(1, h, 2)
    carve(start_x, start_y)
    return maze

# 把小迷宫嵌入大地图中央
full_maze = np.ones((HEIGHT, WIDTH), dtype=int)
inner_maze = dfs_maze(MAZE_W, MAZE_H)

for y in range(MAZE_H):
    for x in range(MAZE_W):
        full_maze[OFFSET_Y + y][OFFSET_X + x] = inner_maze[y][x]

# 选择人物初始位置
for y in range(HEIGHT):
    for x in range(WIDTH):
        if full_maze[y][x] == 0:
            player_x, player_y = x, y
            break
    else:
        continue
    break
# 找到怪物初始位置（从右下角第一个通路）
monster_x, monster_y = None, None
for y in range(HEIGHT-1, -1, -1):
    for x in range(WIDTH-1, -1, -1):
        if full_maze[y][x] == 0:
            monster_x, monster_y = x, y
            break
    if monster_x is not None:
        break
# 生成豆子
def generate_beans(maze, px, py, num_beans):
    h, w = maze.shape
    pos = set()
    while len(pos) < num_beans:
        x = random.randint(0, w - 1)
        y = random.randint(0, h - 1)
        if maze[y][x] == 0 and (x, y) != (px, py):
            pos.add((x, y))
    return list(pos)

beans = generate_beans(full_maze, player_x, player_y, 16)

# 输出 maze.coe
with open("maze.coe", "w") as f:
    f.write("memory_initialization_radix=16;\n")
    f.write("memory_initialization_vector=\n")
    for i in range(HEIGHT):
        for _ in range(CELL_SIZE):
            for j in range(WIDTH):
                color = "000" if full_maze[i][j] else "fff"
                f.write((color + ",") * CELL_SIZE)
            f.write("\n")
# 将人物位置（格子坐标）转换为像素坐标并输出到文件
player_pixel_x = player_x * CELL_SIZE
player_pixel_y = player_y * CELL_SIZE
monster_pixel_x = monster_x * CELL_SIZE
monster_pixel_y = monster_y * CELL_SIZE
with open("player_pos.vh", "w") as f:
    f.write(f"`define PLAYER_INIT_X {player_pixel_x}\n")
    f.write(f"`define PLAYER_INIT_Y {player_pixel_y}\n")
    f.write(f"`define MONSTER_INIT_X {monster_pixel_x}\n")
    f.write(f"`define MONSTER_INIT_Y {monster_pixel_y}\n")

# 输出 wall_data.coe
with open("wall_data.coe", "w") as f:
    f.write("memory_initialization_radix=2;\n")
    f.write("memory_initialization_vector=\n")
    data = [str(full_maze[y][x]) for y in range(HEIGHT) for x in range(WIDTH)]
    f.write(",\n".join(data) + ";\n")

# 输出 bean_map.coe
bean_map = np.zeros_like(full_maze)
for x, y in beans:
    bean_map[y][x] = 1

with open("bean_map.coe", "w") as f:
    f.write("memory_initialization_radix=2;\n")
    f.write("memory_initialization_vector=\n")
    data = [str(bean_map[y][x]) for y in range(HEIGHT) for x in range(WIDTH)]
    f.write(",\n".join(data) + ";\n")

# 输出调试用 txt
with open("wall_data.txt", "w") as f:
    for row in full_maze:
        f.write("".join(str(cell) for cell in row) + "\n")