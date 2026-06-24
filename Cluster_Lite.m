function [x, y] = Cluster_Lite(secuencia, a, b, L, W, o, f, N, ~, P, primer_bloque)
%% Algoritmo Cluster boundary search (Imam y Mir, 1998)
% Evaluación mediante funcion_objetivo (distancia rectilínea con penalización)
l = a .* o + b .* (1 - o);  
w = b .* o + a .* (1 - o);
x = zeros(1, N);
y = zeros(1, N);

colocadas = false(1, N);
act = false(1, N);

for k = 1:N
    i = secuencia(k);
    %% Colocar primer instalación o bloque 
    if ~any(colocadas)
        switch primer_bloque
            case "Aleatorio"
                x(i) = (0.5 * l(i)) + rand() * (L - l(i));
                y(i) = (0.5 * w(i)) +  rand() * (W - w(i));
            case "Esquina"
                 x(i) = l(i) / 2;        y(i) = w(i) / 2;
            case "Centro"
                 x(i) = L / 2;           y(i) = W / 2;
        end
        colocadas(i) = true;
        act(i) = true;
        continue;
    end
    mejor_por_j = nan(1, N); 
    mejores_coord = nan(N, 2);
    Jcol = find(colocadas);
    %% Declarar los bordes izq, der (x), sup, inf (y) en cada  
    for j = find(colocadas)
        %% Esquinas y bordes
        [bordes_cand_derecha, bordes_cand_arriba, bordes_cand_izquierda, bordes_cand_abajo, ...
    y_borde_arriba, x_borde_der, y_borde_abajo, x_borde_izq] = bordes_candidatos(i, j, x, y, l, w);
    
       costos = zeros(1, length(bordes_cand_arriba)) + NaN;       % Para solo identificar los puntos válidos 
       %% Evaluación de bordes hacia arriba arriba y, borde derecho
       for c = 1:length(bordes_cand_arriba)
           y_cand = bordes_cand_arriba(c);
           x_cand =  x_borde_der;

           solapa_lims = (x_cand < l(i) / 2) | (y_cand < w(i) / 2) | (x_cand > L - l(i) / 2) | (y_cand > W - w(i) / 2);
           solapa_inst = any( abs(x_cand - x(Jcol)) < (l(i) + l(Jcol))/2  &  abs(y_cand - y(Jcol)) < (w(i) + w(Jcol))/2 );
           if ~solapa_lims && ~solapa_inst
               x_temp = x;   y_temp = y;
               x_temp(i) = x_cand;   y_temp(i) = y_cand;
               costos(c) = funcion_objetivo(N, a, b, L, W, x_temp, y_temp, o, f, P);
           end
       end

       [mejor_1, idx] = min(costos, [], "omitnan");
       if isnan(mejor_1)
           mejor_borde_y_izq = [NaN, NaN];
       else
           mejor_borde_y_izq = [x_borde_der, bordes_cand_arriba(idx)]; % almacenar 
       end


       %% Evaluación de arriba moviendo de izquiera a derecha en x, borde y arriba
       costos2 = zeros(1, length(bordes_cand_izquierda)) + NaN;       % Para solo identificar los puntos válidos 
       for c = 1:length(bordes_cand_izquierda)
           y_cand = y_borde_arriba;
           x_cand =  bordes_cand_izquierda(c);

           solapa_lims = (x_cand < l(i) / 2) | (y_cand < w(i) / 2) | (x_cand > L - l(i) / 2) | (y_cand > W - w(i) / 2);
           solapa_inst = any( abs(x_cand - x(Jcol)) < (l(i) + l(Jcol))/2  &  abs(y_cand - y(Jcol)) < (w(i) + w(Jcol))/2 );
           if ~solapa_lims && ~solapa_inst
               x_temp = x;   y_temp = y;
               x_temp(i) = x_cand;   y_temp(i) = y_cand;
               costos2(c) = funcion_objetivo(N, a, b, L, W, x_temp, y_temp, o, f, P);
           end 
       end

       [mejor_2, idx] = min(costos2, [], "omitnan");
       if isnan(mejor_2)
          mejor_borde_izq_der = [NaN, NaN];
       else
         mejor_borde_izq_der = [bordes_cand_izquierda(idx), y_borde_arriba]; % almacenar
       end


       %% Evaluación del borde inferior de arriba hacia abajo en y, borde x izquierda
       costos3 = zeros(1, length(bordes_cand_abajo)) + NaN;       % Para solo identificar los puntos válidos 
       for c = 1:length(bordes_cand_abajo)
           y_cand = bordes_cand_abajo(c);
           x_cand =  x_borde_izq;
           solapa_lims = (x_cand < l(i) / 2) | (y_cand < w(i) / 2) | (x_cand > L - l(i) / 2) | (y_cand > W - w(i) / 2);
           solapa_inst = any( abs(x_cand - x(Jcol)) < (l(i) + l(Jcol))/2  &  abs(y_cand - y(Jcol)) < (w(i) + w(Jcol))/2 );
           if ~solapa_lims && ~solapa_inst
               x_temp = x;   y_temp = y;
               x_temp(i) = x_cand;   y_temp(i) = y_cand;
               costos3(c) = funcion_objetivo(N, a, b, L, W, x_temp, y_temp, o, f, P);
           end
       end
       [mejor_3, idx] = min(costos3, [], "omitnan");
       if isnan(mejor_3)
          mejor_borde_y_der = [NaN, NaN];
       else
           mejor_borde_y_der = [x_borde_izq, bordes_cand_abajo(idx)]; % almacenar 
       end
       %% Evaluación del borde inferior de derecha a izquierda en x, borde y abajo
       costos4 = zeros(1, length(bordes_cand_derecha)) + NaN;     % Para solo identificar los puntos válidos
       for c = 1:length(bordes_cand_derecha)
           y_cand = y_borde_abajo;
           x_cand = bordes_cand_derecha(c);
           solapa_lims = (x_cand < l(i) / 2) | (y_cand < w(i) / 2) | (x_cand > L - l(i) / 2) | (y_cand > W - w(i) / 2);
           solapa_inst = any( abs(x_cand - x(Jcol)) < (l(i) + l(Jcol))/2  &  abs(y_cand - y(Jcol)) < (w(i) + w(Jcol))/2 );
           if ~solapa_lims && ~solapa_inst
               x_temp = x;   y_temp = y;
               x_temp(i) = x_cand;   y_temp(i) = y_cand;
               costos4(c) = funcion_objetivo(N, a, b, L, W, x_temp, y_temp, o, f, P);
           end
       end
       [mejor_4, idx] = min(costos4, [], "omitnan");
       if isnan(mejor_4)
           mejor_borde_der_izq = [NaN, NaN];
       else
           mejor_borde_der_izq = [bordes_cand_derecha(idx), y_borde_abajo];   % almacenar 
       end
       %% Seleccionar mejor posición en el bloque j 
       bordes = [mejor_borde_y_izq; mejor_borde_izq_der; mejor_borde_y_der; mejor_borde_der_izq];   % matriz de las mejores coords en cada esquina
       mejores_bloque = [mejor_1, mejor_2, mejor_3, mejor_4];   % Vector de los mejores valores encontrados en cada esquina 
       [mejor_bloque, idx] = min(mejores_bloque, [], "omitnan");

       if isnan(mejor_bloque), continue; end    % Saltar si ya no se encontró dónde colocar en la isntalación j, pasar a la siguiente 
    
       %% Almacenar como matriz las mejores coordenadas en x, y de cada bloque j colocado
       mejores_coord(j, :) = bordes(idx, :); 
       mejor_por_j(j) = mejor_bloque;
    end
    %% Seleccionar el mejor valor de los óptimos de cada bloque 
    J = find(colocadas);
    [mejor_global, idx_mejor] = min(mejor_por_j(J), [], "omitnan");
    if isnan(mejor_global),   x(i) = 0;   y(i) = 0;   break;   end
    j_ganador = J(idx_mejor);            x(i) = mejores_coord(j_ganador, 1);       y(i) = mejores_coord(j_ganador, 2);
    act(i) = true; colocadas(i) = true; 
end
end


%% Bordes críticos 
function [bordes_cand_derecha, bordes_cand_arriba, bordes_cand_izquierda, bordes_cand_abajo, ...
    y_borde_arriba, x_borde_der, y_borde_abajo, x_borde_izq] = bordes_candidatos(i, j, x, y, l, w)
%% Bordes 7 puntos candidatos (arriba) moviendo hacia la derecha 
x_derecha_1 = x(j) - 0.5 * l(j) - 0.5 * l(i);                    y_borde_arriba = y(j) + 0.5 * w(j) + 0.5 * w(i);  
x_derecha_2 = x(j) - 0.5 * l(j);                          
x_derecha_3 = x(j) - 0.5 * l(j) + 0.5 * l(i);          
x_derecha_4 = x(j);                                       
x_derecha_5 = x(j) + 0.5 * l(j) - 0.5 * l(i);   
x_derecha_6 = x(j) + 0.5 * l(j);
x_derecha_7 = x(j) + 0.5 * l(j) + 0.5 * l(i);

bordes_cand_derecha = [x_derecha_1, x_derecha_2, x_derecha_3, x_derecha_4, x_derecha_5, x_derecha_6, x_derecha_7];

%% Bordes 7 puntos candidatos moviendo de Arriba hacia abajo (borde x_derecha)
x_borde_der = x(j) + 0.5 * l(j) + 0.5 * l(i);           y_arriba_1 = y(j) - 0.5 * w(j) - 0.5 * w(i);
                                                        y_arriba_2 = y(j) - 0.5 * w(j);
                                                        y_arriba_3 = y(j) - 0.5 * w(j) + 0.5 * w(i); 
                                                        y_arriba_4 = y(j);
                                                        y_arriba_5 = y(j) + 0.5 * w(j) - 0.5 * w(i);
                                                        y_arriba_6 = y(j) + 0.5 * w(j);  
                                                        y_arriba_7 = y(j) + 0.5 * w(j) + 0.5 * w(i);

bordes_cand_arriba = [y_arriba_1, y_arriba_2, y_arriba_3, y_arriba_4, y_arriba_5, y_arriba_6, y_arriba_7];

%% Bordes 7 puntos candidatos moviendo hacia la Izquierda    (borde y_abajo) tomar el vector de bordes cand en x y contar al revés
bordes_cand_izquierda = [x_derecha_7, x_derecha_6, x_derecha_5, x_derecha_4, x_derecha_3, x_derecha_2, x_derecha_1];
y_borde_abajo = y(j) - 0.5 * w(j) - 0.5 * w(i);

%% Bordes 7 puntos candidatos moviendo de abajo hacia arriba (borde_x_izquierda) tomar el vector de bordes cand en y y contar al revés
x_borde_izq = x(j) - 0.5 * l(j) - 0.5 * l(i); 
bordes_cand_abajo = [y_arriba_7, y_arriba_6, y_arriba_5, y_arriba_4, y_arriba_3, y_arriba_2, y_arriba_1];

end