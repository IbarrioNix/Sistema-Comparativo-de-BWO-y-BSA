% =========================================================================
% bwo_ejemplo.m  -  Script de prueba y COMPARACIÓN: BWO vs BWO_CLUSTER vs BSA
%                   aplicados a distribución de planta
% =========================================================================
clear; clc;

% ----- Cargar datos del problema -----------------------------------------
[N, a, b, L, W, f] = instancias("hard20");

% ----- Parámetros compartidos de los algoritmos --------------------------
poblacion   = 6;  % Número de arañas / soluciones candidatas
iteraciones = 60;   % Número de iteraciones del bucle principal

% =========================================================================
% EJECUTAR BWO  (Black Widow Optimization - abanico)
% =========================================================================
fprintf('\n========================================\n');
fprintf('  Ejecutando BWO...\n');
fprintf('========================================\n');
tic;
[mx_bwo, my_bwo, mo_bwo, msec_bwo, mcosto_bwo] = bwo(N, a, b, L, W, f, poblacion, iteraciones);
tiempo_bwo = toc;

% =========================================================================
% EJECUTAR BWO_CLUSTER  (Black Widow Optimization - Cluster_Lite)
% =========================================================================
fprintf('\n========================================\n');
fprintf('  Ejecutando BWO Cluster...\n');
fprintf('========================================\n');
tic;
[mx_bwoc, my_bwoc, mo_bwoc, msec_bwoc, mcosto_bwoc] = bwo_cluster(N, a, b, L, W, f, poblacion, iteraciones);
tiempo_bwoc = toc;

% =========================================================================
% EJECUTAR BSA  (Bolas Spider Algorithm)
% =========================================================================
fprintf('\n========================================\n');
fprintf('  Ejecutando BSA...\n');
fprintf('========================================\n');
tic;
[mx_bsa, my_bsa, mo_bsa, msec_bsa, mcosto_bsa] = bsa(N, a, b, L, W, f, poblacion, iteraciones);
tiempo_bsa = toc;

% =========================================================================
% COMPARACIÓN DE RESULTADOS
% =========================================================================
fprintf('\n\n╔══════════════════════════════════════════════════════════╗\n');
fprintf(  '║         COMPARACIÓN: BWO  vs  BWO_CLUSTER  vs  BSA      ║\n');
fprintf(  '╠══════════════════════════════════════════════════════════╣\n');
fprintf(  '║  %-10s  %14s  %14s  %14s  ║\n', 'Métrica', 'BWO', 'BWO Cluster', 'BSA');
fprintf(  '╠══════════════════════════════════════════════════════════╣\n');
fprintf(  '║  %-10s  %14.3f  %14.3f  %14.3f  ║\n', 'Costo ($)', mcosto_bwo, mcosto_bwoc, mcosto_bsa);
fprintf(  '║  %-10s  %13.2fs  %13.2fs  %13.2fs  ║\n', 'Tiempo', tiempo_bwo, tiempo_bwoc, tiempo_bsa);
fprintf(  '╚══════════════════════════════════════════════════════════╝\n');

% Determinar ganador
costos  = [mcosto_bwo, mcosto_bwoc, mcosto_bsa];
nombres = {'BWO', 'BWO Cluster', 'BSA'};
[mejor_costo, idx_ganador] = min(costos);
fprintf('\n>> %s encontró la MEJOR solución con costo: $%.3f\n', nombres{idx_ganador}, mejor_costo);

% =========================================================================
% MOSTRAR RESULTADOS DETALLADOS
% =========================================================================
fprintf('\n--- Resultados BWO ---\n');
disp(["Mejor Secuencia: ", mat2str(msec_bwo)])
disp(["Mejor x:         ", mat2str(mx_bwo)])
disp(["Mejor y:         ", mat2str(my_bwo)])
disp(["Mejor o:         ", mat2str(mo_bwo)])
fprintf("Mejor Costo: $%.3f\n", mcosto_bwo)

fprintf('\n--- Resultados BWO Cluster ---\n');
disp(["Mejor Secuencia: ", mat2str(msec_bwoc)])
disp(["Mejor x:         ", mat2str(mx_bwoc)])
disp(["Mejor y:         ", mat2str(my_bwoc)])
disp(["Mejor o:         ", mat2str(mo_bwoc)])
fprintf("Mejor Costo: $%.3f\n", mcosto_bwoc)

fprintf('\n--- Resultados BSA ---\n');
disp(["Mejor Secuencia: ", mat2str(msec_bsa)])
disp(["Mejor x:         ", mat2str(mx_bsa)])
disp(["Mejor y:         ", mat2str(my_bsa)])
disp(["Mejor o:         ", mat2str(mo_bsa)])
fprintf("Mejor Costo: $%.3f\n", mcosto_bsa)

% =========================================================================
% VISUALIZAR LAYOUTS  (requiere visualizar_continua en el path)
% =========================================================================
figure('Name', 'BWO - Mejor layout');
visualizar_continua(mx_bwo, my_bwo, mo_bwo, a, b, L, W);
title(sprintf('BWO  |  Costo: $%.3f  |  Tiempo: %.2fs', mcosto_bwo, tiempo_bwo));

figure('Name', 'BWO Cluster - Mejor layout');
visualizar_continua(mx_bwoc, my_bwoc, mo_bwoc, a, b, L, W);
title(sprintf('BWO Cluster  |  Costo: $%.3f  |  Tiempo: %.2fs', mcosto_bwoc, tiempo_bwoc));

figure('Name', 'BSA - Mejor layout');
visualizar_continua(mx_bsa, my_bsa, mo_bsa, a, b, L, W);
title(sprintf('BSA  |  Costo: $%.3f  |  Tiempo: %.2fs', mcosto_bsa, tiempo_bsa));