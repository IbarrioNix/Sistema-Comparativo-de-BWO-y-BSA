function [mx, my, mo, msec, mcosto] = bsa(N, a, b, L, W, f, poblacion, iteraciones)
% =========================================================================
% BSA - Bolas Spider Algorithm adaptado a distribución de planta
% =========================================================================
% Implementación fiel al paper:
%   "Bolas Spider Algorithm: A Novel Efficient Nature-Inspired Metaheuristic
%    for Complex Continuous Optimization"
%   Qawaqneh et al., IJIES Vol.19, No.1, 2026
%
% Trabaja directamente con:
%   rpi()              -> convierte vector continuo en secuencia de instalaciones
%   abanico()          -> coloca las instalaciones en el plano usando la secuencia
%   funcion_objetivo() -> calcula el costo total con penalizaciones
%
% -------------------------------------------------------------------------
% DESCRIPCIÓN DEL ALGORITMO
% -------------------------------------------------------------------------
% El BSA modela el comportamiento de caza de la araña de bolas (Bolas Spider),
% que usa:
%   1. FASE DE EXPLORACIÓN: la araña emite feromonas para atraer presas hacia
%      posiciones con alto potencial. El movimiento combina dirección hacia
%      posiciones prometedoras con perturbación estocástica en zigzag.
%      Ec. (5): X_i^P1 = X_i + r*(NL_i - I*X_i) + DeltaX_Random
%      Ec. (6): DeltaX_Random = kr * sin(pi/2 * r) * (X_Random - I*X_i)
%
%   2. FASE DE EXPLOTACIÓN: ataque de corto alcance, casi lineal, hacia la
%      mejor presa detectada en la vecindad inmediata.
%      Ec. (8): X_i^P2 = X_i + (1 - 2*r) * R
%      Ec. (9): R = ||(X_best - I*X_i) + (X_Random - I*X_i)|| / (2*t)
%
% En ambas fases se acepta la nueva posición solo si mejora el fitness
% (criterio greedy, Ec. 7 y 10 del paper).
%
% -------------------------------------------------------------------------
% ADAPTACIÓN AL PROBLEMA DE DISTRIBUCIÓN DE PLANTA
% -------------------------------------------------------------------------
% El espacio de búsqueda continuo del BSA original se adapta a distribución
% de planta usando dos vectores por individuo:
%   sh [1xN] -> vector continuo en [0,1]; al ordenarlo con rpi() se obtiene
%               la SECUENCIA de colocación de instalaciones
%   oh [1xN] -> vector continuo en [0,1]; oh(i) > 0.5 rota la instalación i
%
% Cada "araña" = [sh | oh] concatenados -> vector de 2N dimensiones.
% Las operaciones de exploración/explotación del paper se aplican sobre
% estos vectores continuos, y luego se decodifican mediante rpi() y abanico().
%
% -------------------------------------------------------------------------
% ENTRADAS:
%   N          -> Número de instalaciones
%   a          -> Vector [1xN] con el lado corto de cada instalación
%   b          -> Vector [1xN] con el lado largo de cada instalación
%   L          -> Ancho total de la planta (límite en X)
%   W          -> Alto total de la planta (límite en Y)
%   f          -> Matriz [NxN] de flujos entre instalaciones
%   poblacion  -> Número de arañas (soluciones candidatas)
%   iteraciones-> Número máximo de iteraciones del algoritmo
%
% SALIDAS:
%   mx    -> Vector [1xN] con la coordenada X del centro de cada instalación
%   my    -> Vector [1xN] con la coordenada Y del centro de cada instalación
%   mo    -> Vector [1xN] de orientaciones (0 = normal, 1 = rotada 90°)
%   msec  -> Vector [1xN] con el orden en que se colocaron las instalaciones
%   mcosto-> Mejor costo (función objetivo) encontrado
% =========================================================================

% -------------------------------------------------------------------------
% PARÁMETROS DEL ALGORITMO BSA
% (según el paper de Qawaqneh et al., 2026)
% -------------------------------------------------------------------------
P  = 1e3;   % Penalización por solapamiento o salida de límites

% kr: coeficiente de ruido estocástico para el zigzag en la exploración.
% El paper indica kr ∈ [0.1, 0.01], decreciente con las iteraciones.
% Se interpola linealmente de 0.1 (inicio) a 0.01 (final).
kr_ini = 0.1;
kr_fin = 0.01;

% -------------------------------------------------------------------------
% ETAPA 1: INICIALIZACIÓN DE LA POBLACIÓN  (Ec. 2 del paper)
% -------------------------------------------------------------------------
% Cada araña i tiene:
%   sh(i,:) -> vector de secuencia en [0,1]^N
%   oh(i,:) -> vector de orientación en [0,1]^N
% Concatenados forman el vector de posición X_i de dimensión m = 2N
% (análogo al espacio de búsqueda m-dimensional del paper).

sh = rand(poblacion, N);   % Vectores de secuencia  [poblacion x N]
oh = rand(poblacion, N);   % Vectores de orientación [poblacion x N]

% Variables decodificadas del problema
o        = zeros(poblacion, N);
secuencia= zeros(poblacion, N);
x        = zeros(poblacion, N);
y        = zeros(poblacion, N);
Costos   = zeros(1, poblacion);

% Evaluar población inicial
for p = 1:poblacion
    secuencia(p,:) = rpi(sh(p,:));
    o(p,:)         = double(oh(p,:) > 0.5);
    [x(p,:), y(p,:)] = abanico(N, a, b, L, W, o(p,:), secuencia(p,:));
    Costos(p) = funcion_objetivo(N, a, b, L, W, x(p,:), y(p,:), o(p,:), f, P);
end

% Guardar la mejor solución inicial (Ec. 3: identificar X_best)
[mcosto, idx_mejor] = min(Costos);
mx   = x(idx_mejor, :);
my   = y(idx_mejor, :);
mo   = o(idx_mejor, :);
msec = secuencia(idx_mejor, :);

% Vector de posición de la mejor araña (en espacio continuo)
sh_best = sh(idx_mejor, :);
oh_best = oh(idx_mejor, :);

fprintf('=== BSA iniciado | Poblacion: %d | Iteraciones: %d ===\n', poblacion, iteraciones);
fprintf('Iter %4d de %4d | Mejor costo inicial: $%.3f\n', 0, iteraciones, mcosto);

% -------------------------------------------------------------------------
% BUCLE PRINCIPAL DEL ALGORITMO  (Algorithm 1 del paper, líneas 4-15)
% -------------------------------------------------------------------------
for t = 1:iteraciones

    % Calcular kr para esta iteración (decae linealmente de 0.1 a 0.01)
    kr = kr_ini - (kr_ini - kr_fin) * (t - 1) / max(iteraciones - 1, 1);

    % =====================================================================
    % ETAPA 2: FASE DE EXPLORACIÓN — Pheromone-guided global search
    % Paper: Sección 2.3, Ecuaciones (4), (5), (6) y (7)
    % =====================================================================
    % Para cada araña i:
    %   a) Identificar NL_i: conjunto de posiciones con mejor fitness que i,
    %      incluyendo X_best. Seleccionar una al azar. (Ec. 4)
    %   b) Mover hacia NL_i con zigzag estocástico. (Ec. 5 y 6)
    %   c) Aceptar solo si mejora el fitness. (Ec. 7)

    for i = 1:poblacion

        % -- (a) Selección del candidato NL_i (Ec. 4) ---------------------
        % Candidatos: X_best + todas las arañas j con Costo(j) < Costo(i)
        candidatos_sh = sh_best;   % iniciar con X_best
        candidatos_oh = oh_best;
        for j = 1:poblacion
            if j ~= i && Costos(j) < Costos(i)
                candidatos_sh = [candidatos_sh; sh(j,:)]; %#ok<AGROW>
                candidatos_oh = [candidatos_oh; oh(j,:)]; %#ok<AGROW>
            end
        end
        % Seleccionar uno al azar del pool de candidatos
        idx_nl = randi(size(candidatos_sh, 1));
        NL_sh  = candidatos_sh(idx_nl, :);
        NL_oh  = candidatos_oh(idx_nl, :);

        % -- (b) Actualización con zigzag (Ec. 5 y 6) ---------------------
        r = rand();                          % r ∈ [0,1] (Ec. 5)
        I = randi([1, 2]);                   % I ∈ {1,2} parámetro de interacción

        % X_Random: araña aleatoria del espacio de búsqueda (Ec. 6)
        idx_rand  = randi(poblacion);
        XR_sh     = sh(idx_rand, :);
        XR_oh     = oh(idx_rand, :);

        % DeltaX_Random (Ec. 6): perturbación de zigzag
        Delta_sh = kr * sin(pi/2 * r) .* (XR_sh - I .* sh(i,:));
        Delta_oh = kr * sin(pi/2 * r) .* (XR_oh - I .* oh(i,:));

        % Nueva posición candidata (Ec. 5)
        new_sh_p1 = sh(i,:) + r .* (NL_sh - I .* sh(i,:)) + Delta_sh;
        new_oh_p1 = oh(i,:) + r .* (NL_oh - I .* oh(i,:)) + Delta_oh;

        % Mantener valores en [0, 1] (bounds del espacio continuo)
        new_sh_p1 = min(max(new_sh_p1, 0), 1);
        new_oh_p1 = min(max(new_oh_p1, 0), 1);

        % -- (c) Decodificar y evaluar la nueva posición ------------------
        sec_p1 = rpi(new_sh_p1);
        o_p1   = double(new_oh_p1 > 0.5);
        [xp1, yp1] = abanico(N, a, b, L, W, o_p1, sec_p1);
        costo_p1   = funcion_objetivo(N, a, b, L, W, xp1, yp1, o_p1, f, P);

        % Aceptar solo si mejora (Ec. 7: greedy acceptance)
        if costo_p1 < Costos(i)
            sh(i,:)    = new_sh_p1;
            oh(i,:)    = new_oh_p1;
            Costos(i)  = costo_p1;
        end

    end % fin exploración

    % Actualizar X_best tras la fase de exploración
    [costo_exp, idx_exp] = min(Costos);
    if costo_exp < mcosto
        mcosto  = costo_exp;
        sh_best = sh(idx_exp, :);
        oh_best = oh(idx_exp, :);
        msec    = rpi(sh_best);
        mo      = double(oh_best > 0.5);
        [mx, my] = abanico(N, a, b, L, W, mo, msec);
    end

    % =====================================================================
    % ETAPA 3: FASE DE EXPLOTACIÓN — Short-range, goal-directed prey capture
    % Paper: Sección 2.4, Ecuaciones (8), (9) y (10)
    % =====================================================================
    % Para cada araña i:
    %   a) Calcular R: vector de distancia escalado por 1/(2t). (Ec. 9)
    %   b) Mover en dirección casi lineal con pequeña perturbación. (Ec. 8)
    %   c) Aceptar solo si mejora el fitness. (Ec. 10)

    for i = 1:poblacion

        r = rand();       % r ∈ [0,1] (Ec. 8)
        I = randi([1, 2]); % I ∈ {1,2} parámetro de interacción

        % X_Random para la explotación (Ec. 9)
        idx_rand = randi(poblacion);
        XR_sh    = sh(idx_rand, :);
        XR_oh    = oh(idx_rand, :);

        % Vector R (Ec. 9): combinación de X_best e X_Random, escalado por 1/(2t)
        % Norma aplicada componente a componente (valor absoluto de cada dim.)
        R_sh = abs( ((sh_best - I .* sh(i,:)) + (XR_sh - I .* sh(i,:))) / (2 * t) );
        R_oh = abs( ((oh_best - I .* oh(i,:)) + (XR_oh - I .* oh(i,:))) / (2 * t) );

        % Nueva posición candidata (Ec. 8): movimiento casi lineal
        new_sh_p2 = sh(i,:) + (1 - 2*r) .* R_sh;
        new_oh_p2 = oh(i,:) + (1 - 2*r) .* R_oh;

        % Mantener valores en [0, 1]
        new_sh_p2 = min(max(new_sh_p2, 0), 1);
        new_oh_p2 = min(max(new_oh_p2, 0), 1);

        % Decodificar y evaluar la nueva posición
        sec_p2 = rpi(new_sh_p2);
        o_p2   = double(new_oh_p2 > 0.5);
        [xp2, yp2] = abanico(N, a, b, L, W, o_p2, sec_p2);
        costo_p2   = funcion_objetivo(N, a, b, L, W, xp2, yp2, o_p2, f, P);

        % Aceptar solo si mejora (Ec. 10: greedy acceptance)
        if costo_p2 < Costos(i)
            sh(i,:)   = new_sh_p2;
            oh(i,:)   = new_oh_p2;
            Costos(i) = costo_p2;
        end

    end % fin explotación

    % =====================================================================
    % ETAPA 4: ACTUALIZAR MEJOR SOLUCIÓN GLOBAL  (línea 14 del pseudocódigo)
    % =====================================================================
    [costo_iter, idx_iter] = min(Costos);

    if costo_iter < mcosto
        mcosto  = costo_iter;
        sh_best = sh(idx_iter, :);
        oh_best = oh(idx_iter, :);
        msec    = rpi(sh_best);
        mo      = double(oh_best > 0.5);
        [mx, my] = abanico(N, a, b, L, W, mo, msec);
    end

    fprintf('Iteracion: %d, de %d. Mejor costo: $%.3f\n', t, iteraciones, mcosto);

end % fin bucle principal

fprintf('\n=== BSA finalizado ===\n');
fprintf('Mejor costo encontrado: $%.3f\n', mcosto);

end % fin de la función
