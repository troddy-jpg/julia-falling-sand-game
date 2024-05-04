# helpful to read this file:
# ctrl (or command) + shift + p
# 'fold all'    to collapse all functions
# 'unfold all'  to undo


global is_mouse_down = false
global previous_mouse_pos = (0, 0)
global current_mouse_pos = (0, 0)

using Colors

const HEIGHT = 900
const WIDTH = 1200
const GRID_WIDTH = 300
const GRID_HEIGHT = 300
const CELL_SIZE = 5
const MOUSE_SCALE = CELL_SIZE / 2

@enum ElementType Sand Water Stone Nothing
struct Element
    type::ElementType
    color::RGB
end

struct Cell
    element::Element
end

sand = Element(Sand, RGB(1,1,0))  # Yellow
water = Element(Water, RGB(0,0,1))  # Blue
air = Element(Nothing, RGB(1,1,1))  # White

elements_grid = [Cell(air) for _ in 1:(GRID_WIDTH * GRID_HEIGHT)]

function draw(g::Game) 
    # this loop draws every pixel and then updates it, top to bottom
    for x in 1:GRID_WIDTH
        for y in reverse(1:GRID_HEIGHT)
            cell = get_element(x, y)
            posX, posY = (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE
            draw(Rect(posX, posY, CELL_SIZE, CELL_SIZE), cell.element.color, fill=true)
            step(cell.element.type,x,y)
        end
    end
    draw(Circle(Int(round(previous_mouse_pos[1] * CELL_SIZE)), Int(round(previous_mouse_pos[2] * CELL_SIZE)) , 20),RGB(1,0,0))

end

function step(element_type, x, y)
    if element_type == Water
        step_water(x,y,8)
    end
end

function step_water(x, y, dispersion_rate)
    if y < GRID_HEIGHT - 1
        below = get_element(x, y + 1)
        if below.element == air
            set_element(x, y, air)
            set_element(x, y + 1, water)
            return 
        end
    end
    direction = rand([-1, 1]) 
    for i in 1:dispersion_rate
        new_x = x + direction * i
        if new_x >= 1 && new_x <= GRID_WIDTH  
            target = get_element(new_x, y)
            if target.element == air
                set_element(new_x, y, water)
                set_element(x, y, air)
                break  
            end
        else
            break  
        end
    end
end


# Mouse event handlers
function on_mouse_down(g::Game, pos, button)
    global previous_mouse_pos = (Int(round(pos[1] / MOUSE_SCALE)), Int(round(pos[2] / MOUSE_SCALE)))
    global is_mouse_down = true
    # Set water immediately on mouse down
    set_element(previous_mouse_pos[1], previous_mouse_pos[2], water)
end

function on_mouse_move(g::Game, pos)
    current_mouse_pos = (Int(round(pos[1] / MOUSE_SCALE)), Int(round(pos[2] / MOUSE_SCALE)))

    if is_mouse_down
        x,y = current_mouse_pos
        if x in 1:GRID_WIDTH && y in 1:GRID_HEIGHT
            line_points = line_between_points(previous_mouse_pos..., x, y)
            for (px, py) in line_points
                circle_points = points_on_circle(px,py,5)
                for (x2,y2) in circle_points
                    set_element(x2,y2, water)
                end
            end
            global previous_mouse_pos = (x, y)
        end
    end
end

function on_mouse_up(g::Game, pos, button)
    global is_mouse_down = false
end

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

# Some mathematical functions
# Function to generate a line between two points
function line_between_points(x1::Int, y1::Int, x2::Int, y2::Int)
    points = [(x1,y1)]
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

function points_on_circle(x::Real, y::Real, r::Real; n_points::Int=100)
    points = Tuple{Int,Int}[]
    theta_values = LinRange(0, 2π, n_points)
    for theta in theta_values
        x_point = x + r * cos(theta)
        y_point = y + r * sin(theta)
        push!(points, (Int(round(x_point)), Int(round(y_point))))
    end
    return points
    # instead of re-calculating this every frame, why not pre configure a couple brush sizes using this method & save the offsets
end