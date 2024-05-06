const default_brush_offsets = [(-5, -2), (-5, -1), (-5, 0), (-5, 1), (-5, 2), (-4, -4), (-4, -3), (-4, -2), (-4, -1), (-4, 0), (-4, 1), (-4, 2), (-4, 3), (-3, -4), (-3, -3), (-3, -2), (-3, -1), (-3, 0), (-3, 1), (-3, 2), (-3, 3), (-2, -5), (-2, -4), (-2, -3), (-2, -2), (-2, -1), (-2, 0), (-2, 1), (-2, 2), (-2, 3), (-2, 4), (-2, 5), (-1, -5), (-1, -4), (-1, -3), (-1, -2), (-1, -1), (-1, 0), (-1, 1), (-1, 2), (-1, 3), (-1, 4), (-1, 5), (0, -5), (0, -4), (0, -3), (0, -2), (0, -1), (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, -5), (1, -4), (1, -3), (1, -2), (1, -1), (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (2, -5), (2, -4), (2, -3), (2, -2), (2, -1), (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (3, -4), (3, -3), (3, -2), (3, -1), (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (4, -4), (4, -3), (4, -2), (4, -1), (4, 0), (4, 1), (4, 2), (4, 3), (4, 4), (5, -2), (5, -1), (5, 0), (5, 1), (5, 2)]

# helpful to read this file:
# ctrl (or command) + shift + p
# 'fold all'    to collapse all functions
# 'unfold all'  to undo


global is_mouse_down = false
global previous_mouse_pos = (0, 0)
global current_mouse_pos = (0, 0)

using Colors

const HEIGHT = 900
const WIDTH = 900
const GRID_WIDTH = 300
const GRID_HEIGHT = 300
const CELL_SIZE = 5 
const MOUSE_SCALE = CELL_SIZE / 2

@enum ElementType Sand Water Stone Nothing Gas
struct Element
    type::ElementType
    color::RGB
    behavior::Function
end

struct Cell
    element::Element
end

dispersion_rate = 8
function step_water(grid, x, y)
    if y < GRID_HEIGHT - 1
        below = get_element(grid, x, y + 1)
        if below.element == air
            set_element(grid, x, y, air)
            set_element(grid, x, y + 1, water)
            return
        end
    end
    direction = rand([-1, 1])
    for i in 1:dispersion_rate
        new_x = x + direction * i
        if new_x >= 1 && new_x <= GRID_WIDTH
            target = get_element(grid, new_x, y)
            if target.element == air
                set_element(grid, new_x, y, water)
                set_element(grid, x, y, air)
                break
            end
        else
            break
        end
    end
end
function step_sand(grid, x, y)
    if y < GRID_HEIGHT - 1
        below = get_element(grid, x, y + 1)
        if below.element == air
            set_element(grid, x, y, air)
            set_element(grid, x, y + 1, sand)
            return
        elseif below.element == water
            # Swap water with sand
            set_element(grid, x, y, water)
            set_element(grid, x, y + 1, sand)
            return
        end
    end

    options = []
    if y < GRID_HEIGHT - 1 && x > 1 && get_element(grid, x - 1, y + 1).element == air
        push!(options, (x - 1, y + 1))
    end
    if y < GRID_HEIGHT - 1 && x < GRID_WIDTH && get_element(grid, x + 1, y + 1).element == air
        push!(options, (x + 1, y + 1))
    end

    if !isempty(options)
        idx = rand(1:length(options))
        new_x, new_y = options[idx]
        set_element(grid, x, y, air)
        set_element(grid, new_x, new_y, sand)
    end
end
function step_gas(grid, x, y)

    offset = (0,0)
    if y > 1 && y < GRID_HEIGHT
        above = get_element(grid, x, y - 1).element
        if above == air || above == water
            offset = (0,-1) 
        end
    end
    direction = rand([-1,0,1])
    new_x = x + direction
    if new_x >= 1 && new_x <= GRID_WIDTH
        target = get_element(grid, new_x, y).element
        if target == air || target == water
            offset = (new_x, offset[2])
        end
    end    
    if offset != (0,0)
        (x2,y2) = (x + offset[1], y + offset[2])
        target = get_element(grid,x2,y2).element
        set_element(grid, x, y, target)
        set_element(grid, x2, y2, gas)
    end
end
function step_air(grid, x, y)
    # if y > 1
    #     above = get_element(grid, x, y - 1)
    #     if above.element == water
    #         set_element(grid, x, y, water)
    #         set_element(grid, x, y - 1, air)
    #         return
    #     end
    # end
end

sand = Element(Sand, RGB(1, 1, 0), step_sand)  # Yellow
water = Element(Water, RGB(0, 0, 1), step_water)  # Blue
air = Element(Nothing, RGB(0, 0, 0), step_air)  # Black (to match our other game)
gas = Element(Gas,RGB(0,1,0), step_gas) #green

global selected_element = water


grid = [Cell(air) for _ in 1:(GRID_WIDTH*GRID_HEIGHT)]
function draw(g::Game)
    # this loop draws every pixel and then updates it, bottom to top    
    # newGrid = copy(grid)
    for x in 1:GRID_WIDTH
        for y in reverse(1:GRID_HEIGHT)
            cell = get_element(grid, x, y)
            posX, posY = (x - 1) * CELL_SIZE, (y - 1) * CELL_SIZE
            draw(Rect(posX, posY, CELL_SIZE, CELL_SIZE), cell.element.color, fill=true)
            cell.element.behavior(grid, x, y)
        end
    end
    # global grid = newGrid
    
    draw(Circle(Int(round(current_mouse_pos[1] * CELL_SIZE)), Int(round(current_mouse_pos[2] * CELL_SIZE)) , 20),RGB(1,0,0))
    if previous_mouse_pos != (0,0) && is_mouse_down
        line_points = line_between_points(previous_mouse_pos..., current_mouse_pos...)
        for (px, py) in line_points
            circle_points = brush_offsets(px,py)
            for (x2,y2) in circle_points
                set_element(grid, x2,y2, selected_element)
            end
        end
    elseif is_mouse_down
        circle_points = brush_offsets(current_mouse_pos[1],current_mouse_pos[2])
        for (x2,y2) in circle_points
            set_element(grid, x2,y2, selected_element)
        end
    end
    global previous_mouse_pos = current_mouse_pos

end




# Mouse event handlers
function on_mouse_down(g::Game, pos, button)
    global current_mouse_pos = (Int(round(pos[1] / MOUSE_SCALE)), Int(round(pos[2] / MOUSE_SCALE)))
    global is_mouse_down = true
end
function on_mouse_up(g::Game, pos, button)
    global is_mouse_down = false
end
function on_mouse_move(g::Game, pos)
    global current_mouse_pos = (Int(round(pos[1] / MOUSE_SCALE)), Int(round(pos[2] / MOUSE_SCALE)))
end

#element related functions
function describe(element::Element)
    println("Element: $(element.type), Color: $(element.color)")
end
function set_element(grid, x::Int, y::Int, element::Element)
    if 1 > x || x > GRID_WIDTH || 1 > y || y+1 > GRID_HEIGHT
        return # NOT IN BOUNDS
    end
    index = GRID_WIDTH * (y - 1) + x
    grid[index] = Cell(element)
end
function get_element(grid, x::Int, y::Int)
    grid[GRID_WIDTH*(y-1)+x]
end

# Some mathematical functions
function line_between_points(x1::Int, y1::Int, x2::Int, y2::Int)
    points = [(x1, y1)]
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
# function points_on_circle(x::Real, y::Real, r::Real; n_points::Int=100)
#     # instead of re-calculating this every frame, why not pre configure a couple brush sizes using this method & save the offsets
#     points = Tuple{Int,Int}[]
#     theta_values = LinRange(0, 2π, n_points)
#     for theta in theta_values
#         x_point = x + r * cos(theta)
#         y_point = y + r * sin(theta)
#         push!(points, (Int(round(x_point)), Int(round(y_point))))
#     end
#     return points
# end

# function oh_god(points)
#     sorted_points = []

#     count = 1
#     for (r,l) in x_left_right_r5
#         for x in (r:l)
#             push!(sorted_points,(y_r5[count],x))
#         end
#         count += 1
#     end

#     sort(unique(sorted_points))
# end
# println(oh_god(sorted_by_x))


function brush_offsets(px,py) 
    points = []
    for (x_offset,y_offset) in default_brush_offsets
        push!(points,(px+x_offset,py+y_offset))
    end
    return points
end

function update(g::Game)
    if g.keyboard.Q
        global selected_element = water
    elseif g.keyboard.W
        global selected_element = sand
    elseif g.keyboard.E
        global selected_element = air
    elseif g.keyboard.R
        global selected_element = gas
    end
end