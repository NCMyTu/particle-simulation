function love.load()
    love.math.setRandomSeed(os.time())

    windowWidth = 1200
    windowHeight = 600
    love.window.setMode(windowWidth, windowHeight)

    particles = {
        --[[ 
        each particle is a {
            x, y: number,
            radius: number(int)
            dx, dy: number,
            mass: number,
            color: table of rgb value,
        }
        ]]
    }

    particlesPerClick = 7

    particleVelocityMin = 5
    particleVelocityMax = 60

    radiusMin = 5
    radiusMax = 11

    colors = {
        {1.00, 0.00, 0.20},  -- Laser Red
        {0.00, 1.00, 1.00},  -- Laser Blue
        {1.00, 0.38, 0.00},  -- Hot Orange
        {1.00, 0.93, 0.00},  -- Spark Yellow
        {0.00, 1.00, 0.00},  -- Pure Lime Green
        {0.00, 0.75, 1.00},  -- Electric Cyan
        {1.00, 0.20, 0.70},  -- Hot Magenta
    }
end

function love.update(dt)
    for i = 1, #particles do
        local p1 = particles[i]

        -- update particle's velocity
        p1.x = p1.x + p1.dx * dt
        p1.y = p1.y + p1.dy * dt

        handleEdgeCollision(p1, windowWidth, windowHeight)

        -- handle collisions with other particles
        for j = i + 1, #particles do
            local p2 = particles[j]
            local dist = getDistance(p1, p2)
            
            if dist <= p1.radius + p2.radius then
                handleCollision(p1, p2, dist)
            end
        end
    end
end

function love.draw()
    for _, particle in ipairs(particles) do
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3])
        love.graphics.circle("fill", particle.x, particle.y, particle.radius, 50)
        end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(getDebugString(), 5, 5)
end

function getDebugString()
    fpsStr = tostring(love.timer.getFPS()) .. " FPS" .. "\n" .. tostring(#particles) .. " particles"

    return fpsStr
end

function generateParticle(x, y, radiusMin, radiusMax, particleVelocityMin, particleVelocityMax)
    local radius = love.math.random(radiusMin, radiusMax)
    local mass = radius * radius * radius / 1.3
    -- generate uniform velocity in all directions
    local angle = love.math.random() * 2 * math.pi
    local speed = love.math.random(particleVelocityMin, particleVelocityMax)
    local dx = math.cos(angle) * speed
    local dy = math.sin(angle) * speed

    table.insert(particles, {
        x = x, y = y,
        radius = radius,
        -- dx = love.math.random(particleVelocityMin, particleVelocityMax),
        -- dy = love.math.random(particleVelocityMin, particleVelocityMax),
        dx = dx, dy = dy,
        color = colors[love.math.random(1, #colors)],
        mass = mass
    })
end

function generateParticles(nParticles, x, y, radiusMin, radiusMax, particleVelocityMin, particleVelocityMax)
    for i = 1, nParticles do
        generateParticle(x, y, radiusMin, radiusMax, particleVelocityMin, particleVelocityMax)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then -- left mouse
        generateParticles(particlesPerClick, x, y, radiusMin, radiusMax, particleVelocityMin, particleVelocityMax)
    end
end

function getDistance(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    
    return math.sqrt(dx * dx + dy * dy) 
end

function dot(v1, v2)
    return v1.x * v2.x + v1.y * v2.y
end

function handleCollision(p1, p2, dist, dampingFactor)
    dampingFactor = dampingFactor or 1

    handleOverlap(p1, p2, dist)

    -- implementation of https://www.imada.sdu.dk/u/rolf/Edu/DM815/E10/2dhandleCollisions.pdf

    -- normal vector
    local n = {x = p2.x - p1.x, y = p2.y - p1.y}

    -- unit normal vector
    local deno = math.sqrt(n.x * n.x + n.y * n.y)
    local un = {x = n.x / deno, y = n.y / deno}

    -- unit tangent vector
    local ut = {x = -un.y, y = un.x}

    -- particle velocity vectors
    local v1 = {x = p1.dx, y = p1.dy}
    local v2 = {x = p2.dx, y = p2.dy}

    -- scalars
    local v1n = dot(un, v1)
    local v1t = dot(ut, v1)
    local v2n = dot(un, v2)
    local v2t = dot(ut, v2)
    
    -- scalars  
    local v1n_after = (v1n * (p1.mass - p2.mass) + 2 * p2.mass * v2n) / (p1.mass + p2.mass)
    local v2n_after = (v2n * (p2.mass - p1.mass) + 2 * p1.mass * v1n) / (p1.mass + p2.mass)

    -- convert back to vectors
    v1n = {x = v1n_after * un.x, y = v1n_after * un.y}
    v1t = {x = v1t * ut.x, y = v1t * ut.y}
    v2n = {x = v2n_after * un.x, y = v2n_after * un.y}
    v2t = {x = v2t * ut.x, y = v2t * ut.y}

    -- update particle velocities
    p1.dx = (v1n.x + v1t.x) * dampingFactor
    p1.dy = (v1n.y + v1t.y) * dampingFactor
    p2.dx = (v2n.x + v2t.x) * dampingFactor
    p2.dy = (v2n.y + v2t.y) * dampingFactor
end

function handleOverlap(p1, p2, dist)
    -- push 2 particles away if they are overlapping
    local overlap = (p1.radius + p2.radius - dist) / -2
    local n = {x = (p2.x - p1.x) / dist, y = (p2.y - p1.y) / dist}

    p1.x = p1.x + overlap * n.x
    p1.y = p1.y + overlap * n.y

    p2.x = p2.x - overlap * n.x
    p2.y = p2.y - overlap * n.y
end

function handleEdgeCollision(particle, windowWidth, windowHeight)
    local collided = false

    if particle.x < particle.radius then
        particle.x = particle.radius
        particle.dx = -particle.dx
        collided = true
    elseif particle.x > windowWidth - particle.radius then
        particle.x = windowWidth - particle.radius
        particle.dx = -particle.dx
        collided = true
    end

    if particle.y < particle.radius then
        particle.y = particle.radius
        particle.dy = -particle.dy
        collided = true
    elseif particle.y > windowHeight - particle.radius then
        particle.y = windowHeight - particle.radius
        particle.dy = -particle.dy
        collided = true
    end

    return collided
end