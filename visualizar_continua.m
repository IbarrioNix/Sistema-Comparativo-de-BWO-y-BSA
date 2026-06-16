function  visualizar_continua(x, y, o, a, b, L, W) 
%% Paso 1: Declarar li, wi y N
l = a .*  o + b .* (1 - o);   w = b .* o + a .* (1 - o); N = length(a);
%% Paso 2: Crear la Figura 
figure; hold on;
colores = 0.4 + 0.6 * rand(N, 3);
%% Paso 3: Crear el bucle del tamaño de N con base al orden de colocación de la secuencia
for i = 1:N
%% Paso 3.1: Inicializar rectángulos 
    rectangle("Position", [x(i) - 0.5 * l(i), y(i) - 0.5 * w(i), l(i), w(i)], ...
    "EdgeColor", "k", "LineWidth", 2, "FaceColor", colores(i, :));
%% Paso 3.2: Inicializar el texto de cada rectángulo (instalación) en el centro
    text(x(i), y(i), num2str(i), "HorizontalAlignment", "center", "VerticalAlignment", "middle",...
        "FontSize", 20);
        plot(x(i), y(i), "ko", "MarkerSize", 0.5)

end
%% Paso 4: Inicializar los límites de la planta para la figura con base a L y W
xlim([0, L]);   ylim([0, W]);   xlabel("L");   ylabel("W");
grid on;
end