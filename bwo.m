function [mx, my, mo, msec, mcosto] = bwo(N, a, b, L, W, f, poblacion, iteraciones)
% =========================================================================
% BWO_PLANTA - Black Widow Optimization adaptado a distribución de planta
% =========================================================================
% Trabaja directamente con:
%   rpi()              -> convierte vector continuo en secuencia de instalaciones
%   abanico()          -> coloca las instalaciones en el plano usando la secuencia
%   funcion_objetivo() -> calcula el costo total con penalizaciones
%
% -------------------------------------------------------------------------
% ENTRADAS:
%   N          -> Número de instalaciones (ej: 12 para "bodega")
%   a          -> Vector [1xN] con el lado "a" (LADO MAS CORTO) de cada instalación
%   b          -> Vector [1xN] con el lado "b" (LADO MAS LARGO) de cada instalación
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
% PARÁMETROS DEL ALGORITMO BWO
% (valores recomendados por el paper de Hayyolalam & Pourhaji Kazem, 2020)
% -------------------------------------------------------------------------
PP = 0.6;   % Tasa de procreación: fracción de la población que se reproduce
            % Ejemplo: si poblacion=10 y PP=0.6 -> 6 arañas son padres

CR = 0.44;  % Tasa de canibalismo: fracción de hijos que sobreviven
            % Los hijos con peor fitness son "comidos" por sus hermanos

PM = 0.4;   % Tasa de mutación: fracción de individuos que mutan
            % La mutación intercambia dos posiciones aleatorias del vector

P  = 1e3;   % Penalización por solapamiento o salida de límites en la
            % función objetivo

% -------------------------------------------------------------------------
% ETAPA 1: INICIALIZACIÓN DE LA POBLACIÓN
% -------------------------------------------------------------------------
% Cada "araña" (solución candidata) tiene dos vectores continuos:
%   sh -> vector de secuencia: números aleatorios [0,1] que al ordenarse
%          dan el orden en que se colocan las instalaciones (se convierte
%          con rpi() a una permutación discreta)
%   oh -> vector de orientación: si oh(i) > 0.5 -> instalación i se rota

sh = zeros(poblacion, N);  % Matriz de vectores de secuencia  [poblacion x N]
oh = zeros(poblacion, N);  % Matriz de vectores de orientación [poblacion x N]

% Variables del problema (resultado de decodificar sh y oh)
o        = zeros(poblacion, N);  % Orientaciones discretas (0 o 1)
secuencia= zeros(poblacion, N);  % Orden de colocación de instalaciones
x        = zeros(poblacion, N);  % Coordenada X del centro de cada instalación
y        = zeros(poblacion, N);  % Coordenada Y del centro de cada instalación
Costos   = zeros(1, poblacion);  % Costo (fitness) de cada araña

% Generar población inicial aleatoria y evaluar cada araña
for p = 1:poblacion
    sh(p,:) = rand(1, N);   % Vector continuo aleatorio para la secuencia
    oh(p,:) = rand(1, N);   % Vector continuo aleatorio para la orientación

    % Decodificación: convertir vectores continuos a variables del problema
    secuencia(p,:) = rpi(sh(p,:));          % Ordenar sh -> permutación de instalaciones
    o(p,:)         = double(oh(p,:) > 0.5); % oh > 0.5 significa rotar la instalación

    % Colocar instalaciones con la heurística abanico y calcular su costo
    [x(p,:), y(p,:)] = abanico(N, a, b, L, W, o(p,:), secuencia(p,:));
    Costos(p) = funcion_objetivo(N, a, b, L, W, x(p,:), y(p,:), o(p,:), f, P);
end

% Guardar la mejor solución inicial (araña con menor costo)
[mcosto, idx_mejor] = min(Costos);
mx   = x(idx_mejor, :);
my   = y(idx_mejor, :);
mo   = o(idx_mejor, :);
msec = secuencia(idx_mejor, :);

fprintf('=== BWO iniciado | Poblacion: %d | Iteraciones: %d ===\n', poblacion, iteraciones);
fprintf('Iter %4d de %4d | Mejor costo inicial: $%.3f\n', 0, iteraciones, mcosto);

% -------------------------------------------------------------------------
% BUCLE PRINCIPAL DEL ALGORITMO
% -------------------------------------------------------------------------
for iter = 1:iteraciones

    % =====================================================================
    % ETAPA 2: PROCREACIÓN
    % Seleccionar las mejores arañas (padres) y hacer que se reproduzcan.
    % El número de padres está controlado por PP.
    % =====================================================================

    Nr = floor(PP * poblacion);
    % Nr = número de arañas que participan en la reproducción
    % Ejemplo: poblacion=10, PP=0.6 -> Nr=6 arañas son padres

    % Ordenar toda la población de menor a mayor costo (mejor a peor)
    [Costos_ord, idx_ord] = sort(Costos);

    % sh_ord y oh_ord: matrices sh y oh ordenadas por costo
    sh_ord = sh(idx_ord, :);
    oh_ord = oh(idx_ord, :);

    % Separar los Nr mejores como padres
    padres_sh  = sh_ord(1:Nr, :);   % Vectores sh de los padres
    padres_oh  = oh_ord(1:Nr, :);   % Vectores oh de los padres
    costos_pad = Costos_ord(1:Nr);  % Costos de los padres

    % Mezclar aleatoriamente los padres para formar parejas
    orden_parejas = randperm(Nr);   % Permutación aleatoria de 1..Nr
    num_parejas   = floor(Nr / 2);  % Número de parejas posibles

    % Matrices donde iremos acumulando hijos generados
    hijos_sh  = [];  % Vectores sh de los hijos
    hijos_oh  = [];  % Vectores oh de los hijos
    costos_hijos = []; % Costos de los hijos

    % ids_machos: rastrea qué índices (dentro de padres_sh/oh) son machos,
    % para eliminarlos tras el cruce (canibalismo sexual, paso 6 pseudocódigo).
    ids_machos = zeros(1, num_parejas);

    for p = 1:num_parejas
        % Seleccionar dos padres según el orden aleatorio
        idx1 = orden_parejas(2*p - 1);  % Primer candidato
        idx2 = orden_parejas(2*p);      % Segundo candidato

        % Extraer sus vectores continuos
        padre1_sh = padres_sh(idx1, :);
        padre1_oh = padres_oh(idx1, :);
        padre2_sh = padres_sh(idx2, :);
        padre2_oh = padres_oh(idx2, :);

        % Identificar quién es la "hembra" (menor costo = mejor fitness)
        % y quién es el "macho" (mayor costo = peor fitness).
        % El macho será destruido tras el cruce (canibalismo sexual).
        if costos_pad(idx1) <= costos_pad(idx2)
            % padre1 es hembra, padre2 es macho
            hembra_sh = padre1_sh;  hembra_oh = padre1_oh;
            macho_sh  = padre2_sh;  macho_oh  = padre2_oh;
            ids_machos(p) = idx2;   % marcar el macho para eliminarlo
        else
            % padre2 es hembra, padre1 es macho
            hembra_sh = padre2_sh;  hembra_oh = padre2_oh;
            macho_sh  = padre1_sh;  macho_oh  = padre1_oh;
            ids_machos(p) = idx1;   % marcar el macho para eliminarlo
        end

        % ------------------------------------------------------------------
        % CRUCE ARITMÉTICO — el paper repite la Ecuación 1 exactamente
        % Nvar/2 veces usando posiciones NO duplicadas del vector alpha.
        %
        % Interpretación fiel: en cada repetición k se genera un nuevo alpha
        % aleatorio (distinto por construcción al ser rand independiente) y
        % se producen 2 hijos. Con Nvar/2 repeticiones, la pareja genera en
        % total Nvar hijos (Nvar/2 pares), explorando el espacio de forma
        % más amplia que con una sola aplicación de la ecuación.
        %
        % "randomly selected numbers should not be duplicated" → usamos
        % randperm para elegir qué posiciones de alpha son "activas" en
        % cada repetición, garantizando que no se repita ninguna posición
        % a lo largo de las Nvar/2 iteraciones del cruce.
        % ------------------------------------------------------------------

        Nrep = max(1, floor(N / 2));  % número de repeticiones = Nvar/2

        % Construir un orden aleatorio de posiciones sin repetición,
        % que se distribuye entre las Nrep repeticiones del cruce.
        pos_orden = randperm(N);      % permutación aleatoria de 1..N

        for k = 1:Nrep
            % alpha independiente para cada repetición (continuo en [0,1])
            alpha_sh = rand(1, N);
            alpha_oh = rand(1, N);

            % "Activar" solo las posiciones asignadas a esta repetición k.
            % Cada repetición recibe 2 posiciones del pos_orden sin solaparse.
            i_pos = pos_orden(2*k - 1);
            j_pos = pos_orden(min(2*k, N));  % min() protege si N es impar

            % Máscara binaria: solo las dos posiciones activas usan alpha;
            % el resto copia directamente de hembra/macho sin mezcla.
            mascara = zeros(1, N);
            mascara(i_pos) = 1;
            mascara(j_pos) = 1;

            % Hijo 1: mezcla solo en posiciones activas, copia en el resto
            hijo1_sh = mascara .* (alpha_sh .* hembra_sh + (1 - alpha_sh) .* macho_sh) ...
                     + (1 - mascara) .* hembra_sh;
            hijo1_oh = mascara .* (alpha_oh .* hembra_oh + (1 - alpha_oh) .* macho_oh) ...
                     + (1 - mascara) .* hembra_oh;

            % Hijo 2: mezcla simétrica solo en posiciones activas
            hijo2_sh = mascara .* (alpha_sh .* macho_sh + (1 - alpha_sh) .* hembra_sh) ...
                     + (1 - mascara) .* macho_sh;
            hijo2_oh = mascara .* (alpha_oh .* macho_oh + (1 - alpha_oh) .* hembra_oh) ...
                     + (1 - mascara) .* macho_oh;

            % Mantener oh acotado en [0,1] (representa probabilidad de rotación)
            hijo1_oh = max(0, min(1, hijo1_oh));
            hijo2_oh = max(0, min(1, hijo2_oh));

            % Decodificar y evaluar Hijo 1
            sec1 = rpi(hijo1_sh);
            o1   = double(hijo1_oh > 0.5);
            [x1, y1] = abanico(N, a, b, L, W, o1, sec1);
            c1 = funcion_objetivo(N, a, b, L, W, x1, y1, o1, f, P);

            % Decodificar y evaluar Hijo 2
            sec2 = rpi(hijo2_sh);
            o2   = double(hijo2_oh > 0.5);
            [x2, y2] = abanico(N, a, b, L, W, o2, sec2);
            c2 = funcion_objetivo(N, a, b, L, W, x2, y2, o2, f, P);

            % Acumular hijos de esta repetición
            hijos_sh     = [hijos_sh;     hijo1_sh; hijo2_sh]; %#ok<AGROW>
            hijos_oh     = [hijos_oh;     hijo1_oh; hijo2_oh]; %#ok<AGROW>
            costos_hijos = [costos_hijos; c1;        c2      ]; %#ok<AGROW>
        end

        % ------------------------------------------------------------------
        % CANIBALISMO SEXUAL (Sección 3.3 tipo 1, paso 6 del pseudocódigo):
        % "Destroy father" — la hembra destruye al macho tras el cruce.
        % Se marca el índice del macho; los machos se eliminan de la lista
        % de padres DESPUÉS del bucle de parejas para no alterar los índices
        % durante la iteración.
        % ------------------------------------------------------------------
        % (los ids_machos ya fueron registrados arriba)
    end

    % Eliminar los machos de la lista de padres disponibles para pop2.
    % Se construye una máscara lógica sobre 1..Nr y se excluyen los machos.
    ids_machos_unicos = unique(ids_machos);  % por si una pareja duplicó índice
    mask_hembras = true(1, Nr);
    mask_hembras(ids_machos_unicos) = false; % false = macho destruido

    padres2_sh  = padres_sh(mask_hembras, :);
    padres2_oh  = padres_oh(mask_hembras, :);
    costos_pad2 = costos_pad(mask_hembras);

    % =====================================================================
    % ETAPA 3: CANIBALISMO
    % =====================================================================

    % ----- 3a: CANIBALISMO FRATRICIDA ------------------------------------
    % Los hijos se ordenan por costo y solo sobreviven los mejores (CR%).
    % Los hermanos "débiles" son eliminados por los "fuertes".

    [costos_hijos_ord, idx_hijos_ord] = sort(costos_hijos);
    hijos_sh_ord = hijos_sh(idx_hijos_ord, :);
    hijos_oh_ord = hijos_oh(idx_hijos_ord, :);

    Nhijos          = size(hijos_sh_ord, 1);
    Nsobrevivientes = max(1, ceil(CR * Nhijos));
    % Nsobrevivientes = cuántos hijos quedan vivos tras el canibalismo fratricida
    % Ejemplo: con N=12 y num_parejas=3 -> 3*(12/2)*2 = 36 hijos
    %          CR=0.44 -> ceil(15.84) = 16 hijos sobreviven

    hijos_vivos_sh  = hijos_sh_ord(1:Nsobrevivientes, :);
    hijos_vivos_oh  = hijos_oh_ord(1:Nsobrevivientes, :);
    costos_vivos    = costos_hijos_ord(1:Nsobrevivientes);

    % ----- 3b: MATRIFAGIA (Sección 3.3 tipo 3) ---------------------------
    % Cualquier hijo sobreviviente puede "comerse" a CUALQUIER hembra de la
    % población (no solo a la madre de su propia pareja).
    % Si un hijo tiene menor costo que alguna hembra, reemplaza a la PEOR
    % hembra que supera en fitness — esto es fiel al paper que lo plantea
    % de forma general, no restringida a la pareja de origen.

    for h = 1:Nsobrevivientes
        costo_hijo_h = costos_vivos(h);

        if isempty(padres2_sh)
            break  % No quedan hembras (caso extremo con Nr=1)
        end

        % Encontrar la peor hembra actual
        [peor_costo_madre, idx_peor_madre] = max(costos_pad2);

        % Si el hijo es mejor que la peor hembra, la reemplaza (matrifagia)
        if costo_hijo_h < peor_costo_madre
            padres2_sh(idx_peor_madre, :) = hijos_vivos_sh(h, :);
            padres2_oh(idx_peor_madre, :) = hijos_vivos_oh(h, :);
            costos_pad2(idx_peor_madre)   = costo_hijo_h;
        end
    end

    % Unir: padres (con posibles reemplazos) + hijos sobrevivientes
    % Esta es la "pop2" del pseudocódigo del paper
    % (:) convierte cualquier vector a columna para evitar errores de concatenación
    pop2_sh  = [padres2_sh;  hijos_vivos_sh];
    pop2_oh  = [padres2_oh;  hijos_vivos_oh];
    cos2     = [costos_pad2(:); costos_vivos(:)];

    % =====================================================================
    % ETAPA 4: MUTACIÓN
    % La mutación opera sobre toda la población actual (sh, oh).
    % Se selecciona PM% de individuos y se intercambian dos posiciones
    % aleatorias de su vector sh (cambia el orden de colocación).
    % =====================================================================

    Nmut = max(1, floor(PM * poblacion));
    % Nmut = cuántos individuos van a mutar
    % Ejemplo: poblacion=10, PM=0.4 -> 4 individuos mutan

    % Copiar la población actual para mutar sobre ella
    pop3_sh  = sh;
    pop3_oh  = oh;
    cos3     = Costos;

    % Elegir Nmut individuos al azar (sin repetición)
    idx_mutar = randperm(poblacion, min(Nmut, poblacion));

    for k = 1:length(idx_mutar)
        ind_sh = pop3_sh(idx_mutar(k), :);
        ind_oh = pop3_oh(idx_mutar(k), :);

        % Elegir dos posiciones distintas al azar y swap en sh
        % (cambiar el orden relativo de dos instalaciones en la secuencia)
        pos   = randperm(N, 2);
        i_pos = pos(1);
        j_pos = pos(2);

        temp           = ind_sh(i_pos);
        ind_sh(i_pos)  = ind_sh(j_pos);
        ind_sh(j_pos)  = temp;

        % Actualizar el individuo mutado en pop3
        pop3_sh(idx_mutar(k), :) = ind_sh;
        pop3_oh(idx_mutar(k), :) = ind_oh; % oh no cambia en la mutación

        % Evaluar el individuo mutado
        sec_m = rpi(ind_sh);
        o_m   = double(ind_oh > 0.5);
        [xm, ym] = abanico(N, a, b, L, W, o_m, sec_m);
        cos3(idx_mutar(k)) = funcion_objetivo(N, a, b, L, W, xm, ym, o_m, f, P);
    end

    % =====================================================================
    % ETAPA 5: ACTUALIZACIÓN DE LA POBLACIÓN
    % Combinar pop2 (padres + hijos vivos) con pop3 (población mutada),
    % ordenar todo por costo y quedarse con los "poblacion" mejores.
    % =====================================================================

    pop_nueva_sh = [pop2_sh;  pop3_sh];
    pop_nueva_oh = [pop2_oh;  pop3_oh];
    cos_nueva    = [cos2(:);  cos3(:)];  % (:) fuerza columna en ambos casos

    % Ordenar de mejor a peor
    [cos_nueva_ord, idx_nueva_ord] = sort(cos_nueva);
    sh_nueva_ord = pop_nueva_sh(idx_nueva_ord, :);
    oh_nueva_ord = pop_nueva_oh(idx_nueva_ord, :);

    % Quedarse con los "poblacion" mejores individuos para la siguiente iteración
    if size(sh_nueva_ord, 1) >= poblacion
        sh = sh_nueva_ord(1:poblacion, :);
        oh = oh_nueva_ord(1:poblacion, :);
        Costos = cos_nueva_ord(1:poblacion)';
    else
        % Si por alguna razón hubiera menos individuos de los necesarios,
        % rellenar con nuevas arañas aleatorias
        sh = sh_nueva_ord;
        oh = oh_nueva_ord;
        Costos = cos_nueva_ord';
        for extra = size(sh,1)+1 : poblacion
            sh_new = rand(1, N);
            oh_new = rand(1, N);
            sec_e  = rpi(sh_new);
            o_e    = double(oh_new > 0.5);
            [xe, ye] = abanico(N, a, b, L, W, o_e, sec_e);
            ce = funcion_objetivo(N, a, b, L, W, xe, ye, o_e, f, P);
            sh     = [sh;     sh_new]; %#ok<AGROW>
            oh     = [oh;     oh_new]; %#ok<AGROW>
            Costos = [Costos,  ce   ]; %#ok<AGROW>
        end
    end

    % =====================================================================
    % ACTUALIZAR LA MEJOR SOLUCIÓN GLOBAL
    % Si encontramos algo mejor que lo visto hasta ahora, guardarlo.
    % =====================================================================
    [costo_iter, idx_iter] = min(Costos);

    if costo_iter < mcosto
        mcosto = costo_iter;

        % Decodificar el mejor individuo de esta iteración
        msec = rpi(sh(idx_iter, :));
        mo   = double(oh(idx_iter, :) > 0.5);
        [mx, my] = abanico(N, a, b, L, W, mo, msec);
    end

    fprintf('Iteracion: %d, de %d. Mejor costo: $%.3f\n', iter, iteraciones, mcosto);

end % fin del bucle principal

fprintf('\n=== BWO finalizado ===\n');
fprintf('Mejor costo encontrado: $%.3f\n', mcosto);

end % fin de la función