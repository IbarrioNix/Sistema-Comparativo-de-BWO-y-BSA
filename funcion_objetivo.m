function C = funcion_objetivo(N, a, b, L, W, x, y, o, f, P)
% =========================================================================
% FUNCION_OBJETIVO - Calcula el costo total de una distribución de planta
% =========================================================================
% El costo combina dos criterios:
%   1. Distancia rectilínea entre los centros de cada par de instalaciones
%   2. Penalización si dos instalaciones se solapan entre sí o alguna
%      se sale de los límites de la planta
%
% La fórmula final es:
%   C = sum_i sum_j  f(i,j) * (1 + P * B(i,j)) * d(i,j)
%
% -------------------------------------------------------------------------
% ENTRADAS:
%   N   -> Número de instalaciones
%   a   -> Vector [1xN]: lado corto de cada instalación (antes de rotar)
%   b   -> Vector [1xN]: lado largo de cada instalación (antes de rotar)
%   L   -> Largo total de la planta (límite en X)
%   W   -> Ancho total de la planta (límite en Y)
%   x   -> Vector [1xN]: coordenada X del centro de cada instalación
%   y   -> Vector [1xN]: coordenada Y del centro de cada instalación
%   o   -> Vector [1xN]: orientación de cada instalación
%              o(i) = 1 -> instalación i está rotada 90°
%              o(i) = 0 -> instalación i en su orientación original
%   f   -> Matriz [NxN]: flujo entre pares de instalaciones
%              f(i,j) = intensidad de movimiento/interacción entre i y j
%              (triangular superior, f(i,j)=0 si i>=j)
%   P   -> Constante de penalización (ej: 1000)
%              Multiplica el costo de los pares con solapamiento o salida
% -------------------------------------------------------------------------
% SALIDA:
%   C   -> Costo total escalar de la distribución (a minimizar)
% =========================================================================

% -------------------------------------------------------------------------
% PASO 1: Calcular dimensiones reales según orientación
% -------------------------------------------------------------------------
% Si o(i) = 1 (rotada): el lado que ocupa en X es b(i) y en Y es a(i)
% Si o(i) = 0 (normal):  el lado que ocupa en X es a(i) y en Y es b(i)
%
%   l(i) = longitud real de la instalación i en la dirección X
%   w(i) = longitud real de la instalación i en la dirección Y

l = a .* o + b .* (1-o);   % Dimensión en X de cada instalación (tras rotar)
w = b .* o + a .* (1-o);   % Dimensión en Y de cada instalación (tras rotar)

% -------------------------------------------------------------------------
% PASO 2: Matriz de distancias rectilíneas d(i,j)
% -------------------------------------------------------------------------
% d(i,j) = distancia Manhattan entre los centros de i y j
%         = |x(i) - x(j)| + |y(i) - y(j)|
% Solo se calcula la mitad superior (j > i) porque f es triangular superior

d = zeros(N,N);

for i = 1:N-1
    for j = i+1:N
        d(i,j) = abs(x(i)-x(j)) + abs(y(i)-y(j));
    end
end

% -------------------------------------------------------------------------
% PASO 3: Matriz de penalizaciones B(i,j)
% -------------------------------------------------------------------------
% B(i,j) = 1 si el par (i,j) tiene alguna infeasibilidad, 0 si es válido
%
% Dos tipos de infeasibilidad:
%   A) solapa_lim: la instalación i O j se sale de los límites de la planta
%      El centro x(k) debe estar en [l(k)/2,  L - l(k)/2]
%      El centro y(k) debe estar en [w(k)/2,  W - w(k)/2]
%
%      FIX: el original solo verificaba i, dejando sin penalizar los pares
%      donde únicamente j estaba fuera de límites.
%
%   B) solapa_ins: las instalaciones i y j se solapan entre sí
%      Dos rectángulos con centros (x(i),y(i)) y (x(j),y(j)) se solapan si:
%        |x(i)-x(j)| < (l(i)+l(j))/2   Y   |y(i)-y(j)| < (w(i)+w(j))/2

B = zeros(N,N);

for i = 1:N
    for j = i+1:N

        % -- FIX: Verificar si la instalación i se sale de la planta --
        solapa_lim_i = x(i) < 0.5 * l(i)     || ...
                       x(i) > L - 0.5 * l(i) || ...
                       y(i) < 0.5 * w(i)     || ...
                       y(i) > W - 0.5 * w(i);

        % -- FIX: Verificar si la instalación j se sale de la planta --
        solapa_lim_j = x(j) < 0.5 * l(j)     || ...
                       x(j) > L - 0.5 * l(j) || ...
                       y(j) < 0.5 * w(j)     || ...
                       y(j) > W - 0.5 * w(j);

        solapa_lim = solapa_lim_i || solapa_lim_j;

        % -- Verificar si i y j se solapan entre sí --
        dx = abs(x(i) - x(j));         % Distancia entre centros en X
        limx = 0.5 * (l(i) + l(j));    % Mínima separación requerida en X

        dy = abs(y(i) - y(j));         % Distancia entre centros en Y
        limy = 0.5 * (w(i) + w(j));    % Mínima separación requerida en Y

        solapa_ins = dx < limx && dy < limy;  % Solapan si falla en AMBAS direcciones

        % -- Si hay cualquier infeasibilidad, penalizar este par --
        if solapa_lim || solapa_ins
            B(i,j) = 1;
        else
            B(i,j) = 0;
        end

    end
end

% -------------------------------------------------------------------------
% PASO 4: Cálculo del costo total
% -------------------------------------------------------------------------
% Para cada par (i,j) con flujo f(i,j) > 0:
%   - Si no hay infeasibilidad (B=0): costo = f(i,j) * d(i,j)
%   - Si hay infeasibilidad  (B=1): costo = f(i,j) * (1 + P) * d(i,j)

C = sum(sum(f .* (1 + P .* B) .* d));

end