using GameZero 
using Colors 

HEIGHT = 700
# Width of the screen
WIDTH = 600
BACKGROUND = colorant"black"

global elements = []
global isDrawing = false

mouse = Circle(0, 0, 5)

const Gravity = 0.2


mutable struct Element
    posX::Int
    posY::Int
    radius::Int
    velocity::Tuple{Float64, Float64}
end

function draw(g::Game)
    draw(mouse, colorant"blue")
    for c in elements
        draw(Circle(c.posX, c.posY, c.radius), colorant"red", fill=true)
    end
end


function on_mouse_move(g::Game, pos)
    mouse.x = pos[1]
    mouse.y = pos[2]
    if isDrawing
        push!(elements, Element(pos[1], pos[2], 5, (0.0, 0.0)))
    end
end

function update()
    apply_gravity()

end 

function apply_gravity()
    for c in elements
        c.velocity = (c.velocity[1], c.velocity[2] + Gravity)
        new_x, new_y = c.posX + round(Int, c.velocity[1]), c.posY + round(Int, c.velocity[2])
        if new_y + c.radius >= HEIGHT
            new_y = HEIGHT - c.radius
            c.velocity = (0.0, 0.0)  # Stop the circle's movement
        end
        c.posX, c.posY = new_x, new_y
    end
end

function particle_collision()
    for i in elements
        for j in elements
            if collide(Circle(i.posX, i.posY, i.radius), Circle(j.posX, j.posY, j.radius))
                
            end
        end
    end
end

function on_mouse_down(g::Game, pos, button)

    global isDrawing = true

end
 


function on_mouse_up(g::Game, pos, button)
    global isDrawing = false
end