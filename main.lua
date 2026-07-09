-- Variables para nuestras imágenes de fondo
local bg_centro, bg_izq, bg_der
local bg_izqc, bg_derc 
local mesa1, mesa2, poster
local barra 

-- Variables para la lógica del juego
local frame_mesa = 1
local cam_x = 0
local screen_w, screen_h
local estado = "menu" 
local estado_camaras = false 

-- Variables de tiempo para animaciones
local timer_mesa = 0
local mostrar_texto_menu = true
local timer_menu = 0

-- Variables para el estado de las puertas y luces
local puerta_izq = false
local puerta_der = false
local luz_izq = false
local luz_der = false

-- Tablas y variables para los botones y la interfaz
local botones = {}
local barra_scale, barra_w, barra_h_actual, barra_x

function love.load()
    love.window.setMode(0, 0, {fullscreen = true, resizable = false})
    
    screen_w = love.graphics.getWidth()
    screen_h = love.graphics.getHeight()

    local ruta = "assets/images/oficina/"

    bg_centro = love.graphics.newImage(ruta .. "centro.png")
    bg_izq = love.graphics.newImage(ruta .. "izq.png")
    bg_der = love.graphics.newImage(ruta .. "der.png")
    bg_izqc = love.graphics.newImage(ruta .. "izqc.png")
    bg_derc = love.graphics.newImage(ruta .. "derc.png")
    mesa1 = love.graphics.newImage(ruta .. "mesa1.png")
    mesa2 = love.graphics.newImage(ruta .. "mesa2.png")
    poster = love.graphics.newImage(ruta .. "poster.png")
    barra = love.graphics.newImage("assets/images/barra.png")

    -- 1. Calcular el escalado proporcional de la barra
    -- Haremos que ocupe el 40% de la pantalla para que no se estire y se vea bien
    barra_scale = (screen_w * 0.4) / barra:getWidth() 
    barra_w = barra:getWidth() * barra_scale
    barra_h_actual = barra:getHeight() * barra_scale
    barra_x = (screen_w / 2) - (barra_w / 2) -- Centrarla horizontalmente

    local btn_w = screen_w * 0.03 
    local btn_h = screen_h * 0.06 

    botones.puerta_izq = {x = -screen_w * 0.08, y = screen_h * 0.45, w = btn_w, h = btn_h}
    botones.luz_izq    = {x = -screen_w * 0.08, y = screen_h * 0.55, w = btn_w, h = btn_h}
    botones.puerta_der = {x = screen_w * 1.05, y = screen_h * 0.45, w = btn_w, h = btn_h}
    botones.luz_der    = {x = screen_w * 1.05, y = screen_h * 0.55, w = btn_w, h = btn_h}
end

function love.update(dt)
    if estado == "menu" then
        timer_menu = timer_menu + dt
        if timer_menu > 0.5 then
            mostrar_texto_menu = not mostrar_texto_menu
            timer_menu = 0
        end

    elseif estado == "juego" then
        -- Animación de la mesa
        timer_mesa = timer_mesa + dt
        if timer_mesa > 0.05 then
            frame_mesa = frame_mesa == 1 and 2 or 1
            timer_mesa = 0
        end

        -- 2. Lógica de HOVER para la barra de cámaras
        local mouse_x, mouse_y = love.mouse.getPosition()
        
        if not estado_camaras then
            -- Si las cámaras están cerradas, checamos colisión con la barra de abajo
            if mouse_x >= barra_x and mouse_x <= (barra_x + barra_w) and mouse_y >= (screen_h - barra_h_actual) then
                estado_camaras = true
            end
            
            -- Lógica del movimiento con el mouse (Solo se mueve si las cámaras están cerradas)
            local target_cam_x = ((mouse_x / screen_w) * 2 - 1) * screen_w
            cam_x = cam_x + (target_cam_x - cam_x) * dt * 5
        else
            -- Si las cámaras están abiertas, checamos colisión con la barra de arriba
            if mouse_x >= barra_x and mouse_x <= (barra_x + barra_w) and mouse_y <= barra_h_actual then
                estado_camaras = false
            end
        end
    end
end

-- 3. Detectar clics SOLO para botones (la barra ya funciona por hover)
function love.mousepressed(x, y, button, istouch, presses)
    if estado == "juego" and button == 1 then 
        if not estado_camaras then -- Si estamos en las cámaras, no puedes clickear puertas
            local mouse_mundo_x = x + cam_x
            local mouse_mundo_y = y

            local function clic_en_boton(btn)
                return mouse_mundo_x >= btn.x and mouse_mundo_x <= (btn.x + btn.w) and
                       mouse_mundo_y >= btn.y and mouse_mundo_y <= (btn.y + btn.h)
            end

            if clic_en_boton(botones.puerta_izq) then
                puerta_izq = not puerta_izq
            elseif clic_en_boton(botones.luz_izq) then
                luz_izq = not luz_izq
            elseif clic_en_boton(botones.puerta_der) then
                puerta_der = not puerta_der
            elseif clic_en_boton(botones.luz_der) then
                luz_der = not luz_der
            end
        end
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    
    if estado == "menu" and (key == "return" or key == "kpenter") then
        estado = "juego"
    end
end

function love.draw()
    if estado == "menu" then
        love.graphics.clear(0, 0, 0)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Aga Ta", screen_w * 0.1, screen_h * 0.2, 0, 4, 4)
        love.graphics.print("Fedi's", screen_w * 0.1, screen_h * 0.3, 0, 4, 4)
        
        if mostrar_texto_menu then
            love.graphics.print(">> Presiona ENTER para jugar <<", screen_w * 0.1, screen_h * 0.7, 0, 2, 2)
        end
        
    elseif estado == "juego" then
        love.graphics.clear(1, 1, 1)
        
        -- CAPA DE LA OFICINA
        love.graphics.push()
        love.graphics.translate(-cam_x, 0)
        love.graphics.setColor(1, 1, 1)

        local scale_izq_x, scale_izq_y = screen_w / bg_izq:getWidth(), screen_h / bg_izq:getHeight()
        local scale_cen_x, scale_cen_y = screen_w / bg_centro:getWidth(), screen_h / bg_centro:getHeight()
        local scale_der_x, scale_der_y = screen_w / bg_der:getWidth(), screen_h / bg_der:getHeight()

        if puerta_izq then
            local scale_izqc_x, scale_izqc_y = screen_w / bg_izqc:getWidth(), screen_h / bg_izqc:getHeight()
            love.graphics.draw(bg_izqc, -screen_w, 0, 0, scale_izqc_x, scale_izqc_y)
        else
            love.graphics.draw(bg_izq, -screen_w, 0, 0, scale_izq_x, scale_izq_y)
        end

        love.graphics.draw(bg_centro, 0, 0, 0, scale_cen_x, scale_cen_y)

        if puerta_der then
            local scale_derc_x, scale_derc_y = screen_w / bg_derc:getWidth(), screen_h / bg_derc:getHeight()
            love.graphics.draw(bg_derc, screen_w, 0, 0, scale_derc_x, scale_derc_y)
        else
            love.graphics.draw(bg_der, screen_w, 0, 0, scale_der_x, scale_der_y)
        end

        -- Botones
        if puerta_izq then love.graphics.setColor(1, 0, 0) else love.graphics.setColor(0, 1, 0) end
        love.graphics.rectangle("fill", botones.puerta_izq.x, botones.puerta_izq.y, botones.puerta_izq.w, botones.puerta_izq.h)
        
        if luz_izq then love.graphics.setColor(1, 1, 1) else love.graphics.setColor(0.3, 0.3, 0.3) end
        love.graphics.rectangle("fill", botones.luz_izq.x, botones.luz_izq.y, botones.luz_izq.w, botones.luz_izq.h)

        if puerta_der then love.graphics.setColor(1, 0, 0) else love.graphics.setColor(0, 1, 0) end
        love.graphics.rectangle("fill", botones.puerta_der.x, botones.puerta_der.y, botones.puerta_der.w, botones.puerta_der.h)

        if luz_der then love.graphics.setColor(1, 1, 1) else love.graphics.setColor(0.3, 0.3, 0.3) end
        love.graphics.rectangle("fill", botones.luz_der.x, botones.luz_der.y, botones.luz_der.w, botones.luz_der.h)

        love.graphics.setColor(1, 1, 1)
        local escala_poster = 0.25
        local poster_x = (screen_w / 2) - ((poster:getWidth() * escala_poster) / 2)
        local poster_y = screen_h * 0.25
        love.graphics.draw(poster, poster_x, poster_y, 0, escala_poster, escala_poster)

        local imagen_mesa_actual = frame_mesa == 1 and mesa1 or mesa2
        local escala_mesa = (screen_w * 0.7) / imagen_mesa_actual:getWidth() 
        local mesa_x = (screen_w / 2) - ((imagen_mesa_actual:getWidth() * escala_mesa) / 2)
        local ajuste_piso = 30 
        local mesa_y = screen_h - (imagen_mesa_actual:getHeight() * escala_mesa) + ajuste_piso 
        love.graphics.draw(imagen_mesa_actual, mesa_x, mesa_y, 0, escala_mesa, escala_mesa)

        love.graphics.pop() 
        
        -- CAPA DE INTERFAZ ESTÁTICA
        if estado_camaras then
            -- Fondo y placeholder
            love.graphics.setColor(0, 0, 0, 0.85)
            love.graphics.rectangle("fill", 0, 0, screen_w, screen_h)
            love.graphics.setColor(0.15, 0.15, 0.15)
            love.graphics.rectangle("fill", screen_w * 0.05, screen_h * 0.15, screen_w * 0.65, screen_h * 0.7)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("CAM 01 - MONITOREO EN VIVO", screen_w * 0.07, screen_h * 0.18, 0, 1.5, 1.5)
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", screen_w * 0.75, screen_h * 0.4, screen_w * 0.2, screen_h * 0.45)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", screen_w * 0.75, screen_h * 0.4, screen_w * 0.2, screen_h * 0.45)
            love.graphics.print("[ MAPA ]", screen_w * 0.82, screen_h * 0.6, 0, 1.5, 1.5)

            -- 4. Barra Arriba Proporcional (Hover)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(barra, barra_x, barra_h_actual, 0, barra_scale, -barra_scale)
        else
            -- Barra Abajo Proporcional (Hover)
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(barra, barra_x, screen_h - barra_h_actual, 0, barra_scale, barra_scale)
        end
    end
end