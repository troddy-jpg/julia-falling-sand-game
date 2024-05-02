using Colors

const HEIGHT = 900
const WIDTH = 1200
const GRID_WIDTH = 300
const GRID_HEIGHT = 300
const CELL_SIZE = 5
const MOUSE_SCALE = CELL_SIZE / 2

@enum ElementType Sand Water Stone Empty

struct Element
    type::ElementType
    color::RGB
end

struct Cell
    element::Element
end

# Define game elements with colors
sand = Element(Sand, RGB(1,1,0))  # Yellow
water = Element(Water, RGB(0,0,1))  # Blue
air = Element(Empty, RGB(1,1,1))  # White

# Initialize elements grid
function initialize_grid(width::Int, height::Int)
    elements = Vector{Cell}(undef, width * height)
    for i in eachindex(elements)
        elements[i] = Cell(air)
    end
    elements
end

elements_grid = initialize_grid(GRID_WIDTH, GRID_HEIGHT)

# Mouse interaction variables
is_mouse_down = false
previous_mouse_pos = (0, 0)

# Function to describe an element
function describe(element::Element)
    println("Element: $(element.type), Color: $(element.color)")
end

# Function to set an element at a specific grid position
function set_element(x::Int, y::Int, element::Element)
    index = GRID_WIDTH * (y - 1) + x
    elements_grid[index] = Cell(element)
end

function get_element(x::Int, y::Int)
    elements_grid[GRID_WIDTH * (y - 1) + x]
end

# Function to generate a line between two points
function line_between_points(x1::Int, y1::Int, x2::Int, y2::Int)
    points = []
    dx = abs(x2 - x1)
    dy = -abs(y2 - y1)
    sx = x1 < x2 ? 1 : -1
    sy = y1 < y2 ? 1 : -1
    err = dx + dy
    while true
        push!(points, (x1, y1))
        if x1 == x2 && y1 == y2
            break
        end
        e2 = 2 * err
        if e2 >= dy
            err += dy
            x1 += sx
        end
        if e2 <= dx
            err += dx
            y1 += sy
        end
    end
    points
end

# Mouse event handlers
function on_mouse_down(g::Game, pos, button)
    global previous_mouse_pos = (Int(round(pos[1] / MOUSE_SCALE)), Int(round(pos[2] / MOUSE_SCALE)))
    global is_mouse_down = true
    # Set water immediately on mouse down
    set_element(previous_mouse_pos[1], previous_mouse_pos[2], water)
end

function on_mouse_move(g::Game, pos)
    if is_mouse_down
        x, y = (Int(round(pos[1] / MOUSE_SCALE)), Int(round(pos[2] / MOUSE_SCALE)))
        if x in 1:GRID_WIDTH && y in 1:GRID_HEIGHT
            line_points = line_between_points(previous_mouse_pos..., x, y)
            for (px, py) in line_points
                set_element(px, py, water)
            end
            global previous_mouse_pos = (x, y)
        end
    end
end

function on_mouse_up(g::Game, pos, button)
    global is_mouse_down = false
end

function draw(g::Game)
    for x in 1:GRID_WIDTH
        for y in 1:GRID_HEIGHT
            cell = get_element(x, y)
            posX, posY = (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE
            draw(Rect(posX, posY, CELL_SIZE, CELL_SIZE), cell.element.color, fill=true)
        end
    end
end

function update(g::Game)
    for x in 1:GRID_WIDTH
        for y in 1:GRID_HEIGHT
            cell = get_element(x, y)
            if cell.element.type == Water
                step_water(x, y, 5)
            end
        end
    end
end

function step_water(x, y, dispersion_rate)
    # Check below first
    if y < GRID_HEIGHT - 1
        below = get_element(x, y + 1)
        if below.element == air
            set_element(x, y, air)
            set_element(x, y + 1, water)
            return # Exit after moving water down
        end
    end

    # If can't move down, try to disperse sideways
    direction = rand([-1, 1]) 
    for i in 1:dispersion_rate
        new_x = x + direction * i
        if new_x >= 1 && new_x <= GRID_WIDTH  # Ensure within bounds
            target = get_element(new_x, y)
            if target.element == air
                set_element(new_x, y, water)
                set_element(x, y, air)
                break  # Stop after moving water to the first available air cell
            end
        else
            break  # Break if out of grid bounds
        end
    end
end