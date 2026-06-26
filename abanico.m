function [x, y] = abanico(N, a, b, L, W, o, secuencia)
    l = a .* o + b .* (1-o);
    w = b .* o + a .* (1-o);
    x = zeros(1,N);
    y = zeros(1,N);
    colocadas = false(1,N);

    for k = 1:N
        i = secuencia(k);
        colocado = false;

        %% Si no se ha colocado nada, colocar la primera instalación
        %% en la esquina inferior izquierda.
        if ~any(colocadas)
            x(i) = 0.5*l(i);
            y(i) = 0.5*w(i);
            colocadas(i) = true;
            continue;
        end

        %% Intentar colocar hacia arriba de cada instalación ya colocada
        for j = find(colocadas)
            x_c = x(j) - 0.5 * l(j) + 0.5 * l(i);
            y_c = y(j) + 0.5 * w(j) + 0.5 * w(i);

            if x_c >= 0.5*l(i) && x_c <= L - 0.5*l(i) && ...
               y_c >= 0.5*w(i) && y_c <= W - 0.5*w(i)

                solapa = false;
                for jj = find(colocadas)
                    dx = abs(x_c - x(jj));
                    limx = 0.5 * (l(i) + l(jj));
                    dy = abs(y_c - y(jj));
                    limy = 0.5 * (w(i) + w(jj));
                    if dx < limx && dy < limy
                        solapa = true;
                        break;
                    end
                end

                if ~solapa
                    x(i) = x_c;
                    y(i) = y_c;
                    colocadas(i) = true;
                    colocado = true;
                    break;
                end
            end
        end

        if colocado
            continue;
        end

        %% Intentar colocar hacia la derecha de cada instalación ya colocada
        for j = find(colocadas)
            x_c = x(j) + 0.5 * l(j) + 0.5 * l(i);
            y_c = y(j) - 0.5 * w(j) + 0.5 * w(i);

            if x_c >= 0.5*l(i) && x_c <= L - 0.5*l(i) && ...
               y_c >= 0.5*w(i) && y_c <= W - 0.5*w(i)

                solapa = false;
                for jj = find(colocadas)
                    dx = abs(x_c - x(jj));
                    limx = 0.5 * (l(i) + l(jj));
                    dy = abs(y_c - y(jj));
                    limy = 0.5 * (w(i) + w(jj));
                    if dx < limx && dy < limy
                        solapa = true;
                        break;
                    end
                end

                if ~solapa
                    x(i) = x_c;
                    y(i) = y_c;
                    colocadas(i) = true;
                    colocado = true;  % FIX: faltaba esta línea en el original
                    break;
                end
            end
        end

        if colocado
            continue;
        end

        %% FIX: Fallback — ninguna dirección funcionó.
        %% Colocar fuera de la planta (coordenadas negativas) para que:
        %%   1. La función objetivo lo penalice correctamente.
        %%   2. No interfiera con la verificación de solapamiento de
        %%      instalaciones futuras (que sí están dentro del plano).
        %% Se marca como colocada para que no bloquee las siguientes.
        x(i) = -l(i);
        y(i) = -w(i);
        colocadas(i) = true;
    end
end