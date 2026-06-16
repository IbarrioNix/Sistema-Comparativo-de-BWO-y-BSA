function [x, y] = abanico(N, a, b, L, W, o, secuencia)
    l = a .* o + b .* (1-o);
    w = b .* o + a .* (1-o);
    x = zeros(1,N);
    y = zeros(1,N);
    colocadas = false(1,N);

    for k = 1:N
        i = secuencia(k);
        colocado = false;
        %%Si no se coloca nada, se coloca la primera instalacion de la
        %%secuencia en la esquina inferior izquierda.
        if ~any(colocadas)
            x(i) = 0.5*l(i);
            y(i) = 0.5*w(i);
            colocadas(i) = true;
            continue;
        end

        %%Colocar hacia arriba
        for j = find(colocadas)
            x_c = x(j) - 0.5 * l(j) + 0.5 * l(i);
            y_c = y(j) + 0.5 * w(j) + 0.5 * w(i);

            %% Verficiacion de solapamientos
            if x_c  >= 0.5 * l(i) && x_c <= L - 0.5 * l(i) && y_c >= 0.5 * w(i) && y_c <= W - 0.5 * w(i) 
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
                    x(i)= x_c;
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

        %%Colocado hacia la derecha
        
        for j = find(colocadas)
            x_c = x(j) + 0.5 * l(j) + 0.5 * l(i);
            y_c = y(j) - 0.5 * w(j) + 0.5 * w(i);

            %% Verficiacion de solapamientos
            if x_c  >= 0.5 * l(i) && x_c <= L-0.5*l(i) && y_c >=0.5 * w(i) && y_c <= W-0.5 * w(i) 
                solapa = false;

                for jj=find(colocadas)
                    dx = abs(x_c-x(jj));
                    limx = 0.5 * (l(i)+l(jj));

                    dy = abs(y_c-y(jj));
                    limy = 0.5 * (w(i)+w(jj));

                    if dx < limx && dy < limy
                        solapa = true;
                        break;
                    end
                end
                
                if ~solapa 
                    x(i)= x_c;
                    y(i) = y_c;
                    colocadas(i) = true;
                    break;
                end
            end
        end
    end
end