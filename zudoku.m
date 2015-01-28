function [res] = zudoku(im)
	%
	%	im - imagen a utilizar
	%
	% Creditos:
	%   Baltazar Ochagavia
	%   Enrique Correa

	%byn = im2bw(im,graythresh(im)*0.91); % transformamos a blanco y negro
	% Blanco y negro por partes
    fun = @(ima) im2bw(ima.data,graythresh(ima.data));
    byn = ~blockproc(im,[200 200],fun);
    %byn = imcomplement(adaptivethresh(im, round(min(size(im,1), size(im,2))/20), 15));
    imshow(byn);
    %return
    % recortar y solo pescar al medio
    % cuadrado = [min(size(im,1), size(im,2)) ] %[xmin ymin width height]
    % i = imcrop(I, [])

    % limpiamos imagen
	byn= imclearborder(byn); % limpiamos bordes 
	byn = bwareaopen(byn, 25); % eliminamos objetos menores a 20 px
	imshow(byn);
	hold on;

	% Buscamos el mayor cuadrado
    R = regionprops(byn,'Area','BoundingBox','PixelList');

    if numel(R) == 0
    	error('No se encontraron elementos BoundingBox')
    end 

    for k = 1 : numel(R)
	  caja = R(k).BoundingBox;
	  rectangle('Position', [caja(1),caja(2),caja(3),caja(4)],...
	  'EdgeColor','r','LineWidth',1 )
	end
    
    % Buscamos area maxima
    maxArea = -1;
    kmax = -1;
    for k = 1 : numel(R)
        if R(k).Area > maxArea
            maxArea = R(k).Area;
            kmax = k;
        end
    end
    
    rectangle('Position', [R(kmax).BoundingBox(1),R(kmax).BoundingBox(2), ...
    	R(kmax).BoundingBox(3),R(kmax).BoundingBox(4)], 'EdgeColor','g','LineWidth', 2);
    
    % Si tenemos algo grande seguimos, sino no
    if prod(R(kmax).BoundingBox(3:4)) < (min(size(im,1), size(im,2))*0.7)^2
    	error('No se encontro ningun rectangulo lo suficientemente grande');
    end

    % sacamos bordes de la caja de la lista de pixeles
	distanciasCeroCero = sum((R(kmax).PixelList - zeros(size(R(kmax).PixelList, 1), 2)).^2, 2);
	[ia pia] = min(distanciasCeroCero);
	[dab pdab] = max(distanciasCeroCero);
	distanciasCeroFin = sum((R(kmax).PixelList - repmat([0 size(im,2)], size(R(kmax).PixelList, 1),1)).^2, 2);
	[da pda] = min(distanciasCeroFin);
	[iab piab] = max(distanciasCeroFin);
	%  Como se dibuja:
	%  1 -- 4
	%  |    |
	%  2 -- 3
    caja = R(kmax).PixelList([pia pda pdab piab], :);
    for i = 1:4
    	plot(caja(i,1),caja(i,2),'r.','MarkerSize',20);
    end
    % dibujamos lineas afuera
    line(caja(1:2,1),caja(1:2,2),'Marker','.','LineStyle', '-', 'LineWidth', 3);
    line(caja(2:3,1),caja(2:3,2),'Marker','.','LineStyle', '-', 'LineWidth', 3);
    line(caja(3:4,1),caja(3:4,2),'Marker','.','LineStyle',' -', 'LineWidth', 3);
    line([caja(1,1) caja(4,1)],[caja(1,2) caja(4,2)],'Marker','.','LineStyle', '-', 'LineWidth', 3);
    % Dividimos y dibujamos lineas interiores
    for i=1:8
        arriba = caja(1, :) + (caja(4,:)-caja(1,:)) .* i/9;
        abajo = caja(2, :) + (caja(3,:)-caja(2,:)) .* i/9;
        line([arriba(1, 1) abajo(1,1)], [arriba(1,2) abajo(1,2)],'Marker','.','LineStyle','-', 'LineWidth', 1);

        izquierda = caja(1, :) + (caja(2,:)-caja(1,:)) .* i/9;
        derecha = caja(4, :) + (caja(3,:)-caja(4,:)) .* i/9;
        line([izquierda(1, 1) derecha(1,1)], [izquierda(1,2) derecha(1,2)],'Marker','.','LineStyle','-', 'LineWidth', 1);
    end

    % proyectamos a cuadrado
    [im, xdata, ydata, cajanueva] = homografia(im,[caja(2, :); caja(3, :); caja(4, :); caja(1, :)]);
    %h = imshow(im,'XData', xdata, 'YData', ydata);
    [nrows,ncols,ncolors] = size(im); % linea maldita, me costo caleta
    for i = 1:4
        plot(caja(i,1),caja(i,2),'g.','MarkerSize',20);
    end
    for i = 1:4
        plot(cajanueva(i,1),cajanueva(i,2),'r.','MarkerSize',20);
    end
    hold off;
    % dividimos matriz a cada digito
    cajanueva = [ axes2pix(ncols, xdata, cajanueva(1,1)) axes2pix(nrows, ydata, cajanueva(1,2)); ...
                  axes2pix(ncols, xdata, cajanueva(2,1)) axes2pix(nrows, ydata, cajanueva(2,2)); ...
                  axes2pix(ncols, xdata, cajanueva(3,1)) axes2pix(nrows, ydata, cajanueva(3,2)); ...
                  axes2pix(ncols, xdata, cajanueva(4,1)) axes2pix(nrows, ydata, cajanueva(4,2))];
    cajanueva = round(cajanueva);
    % imshow(im(cajanueva(4,2):cajanueva(1,2), cajanueva(4,1):cajanueva(3,1)))
    partes = divisionMatriz(im, cajanueva);
    i = 1;
    for y = 1:9
        for x = 1:9
            partes{x,y} = imcomplement(im2bw(partes{x,y},graythresh(partes{x,y})));
            px = linspace(round(size((partes{x,y}),2)/2*0.85), round(size((partes{x,y}),2)/2*1.15), 7);
            py = linspace(round(size((partes{x,y}),1)/2*0.85), round(size((partes{x,y}),1)/2*1.15), 7);
            partes{x,y}  = bwselect(partes{x,y},px, py, 4);
            %subplot(9,9,i), imshow(partes{x,y});
            i = i + 1;
        end
    end  
    % identificamos en cada lugar un numero si existe
    matriz = zeros(9,9);
    partes
    m = 1;
    for y = 1:9
        for x = 1:9
            parte = partes{x,y};
            % si esta todo vacio
            % encontramos elementos
            [i,j] = find(parte);
            if isempty(i)
                continue;
            end
            % hacemos cuadrado
            numero = parte(min(i):max(i), min(j):max(j));
            % primero aprendemremos
            subplot(7,7,m), imshow(numero)
            calculoVectores(numero)
            % imshow(numero);
            matriz(y, x) = reconocerNumero(numero);
            m = m + 1;
        end
    end

    fprintf('[!] Se detecto la siguiente matriz:');
    matriz

    % resolvemos zudoku
    resultado = sodoku_solver(matriz);
    
    % ponemos resultado en imagen
    fprintf('[!] El resultado es el siguiente:');
    resultado
    

    %imshow(im);
    %hold on;
    for y = 1:9
        for x = 1:9
            if matriz(y, x) ~= 0
                continue;
            end
            % dibujamos
            inicio_x = cajanueva(4, 1) + (cajanueva(3,1)-cajanueva(4,1)) .* (x - 1) /9 + (cajanueva(3,1)-cajanueva(4,1)) / 9 / 2;
            inicio_y = cajanueva(4, 2) + (cajanueva(1,2)-cajanueva(4,2)) .* (y - 1) /9 + (cajanueva(3,1)-cajanueva(4,1)) / 9 / 2;
            % text(inicio_x, inicio_y, int2str(resultado(y, x)),'fontweight','bold', 'horiz','cen', 'FontSize', 20, 'Color', 'green');
        end
    end
    % hold off;
end

% metodo que divide el zudoku en una matriz
function [numeros] = divisionMatriz(im, caja)
    numeros = cell(9,9);
    for x = 0:8
        for y = 0:8
            inicio_x = caja(4, 1) + (caja(3,1)-caja(4,1)) .* x /9;
            fin_x = inicio_x + (caja(3,1)-caja(4,1)) / 9;
            inicio_y = caja(4, 2) + (caja(1,2)-caja(4,2)) .* y/9;
            fin_y = inicio_y + (caja(1,2)-caja(4,2)) / 9;
            numeros{x+1, y+1} = im(round(inicio_y):round(fin_y), round(inicio_x):round(fin_x));
        end
    end
end

% reconocimiento de el numero
function [res] = reconocerNumero(im)
    % entrenamos
    % sacamos diferencia
    % menor diferencia es el numero
    aprendidos = [ ...
        1, 0.5060, 0.7711, 0.5060, 0.2289, 0.7619, 4.7619, 5.2857, 1.7143, 0, 0, 0, 0, 0.1515, 2.3939, 3.3636, 1.4545; ... %%
        2, 0.3304, 0.7652, 0.7913, 0.3652, 0.3684, 1.5158, 1.7579, 0.9053, 0.8810, 2.2143, 1.7262, 0.6786, 0.2743, 1.8053, 0.8584, 0.1504; ... %%
        3, 0.3030, 0.9773, 1.0758, 0.6439, 0.3061, 2.0204, 1.7755, 0.6939, 0.6693, 1.4331, 0.9370, 0.4331, 0.1682, 1.7664, 1.7196, 0.8131; ... %%
        4, 0.5659, 0.8062, 0.9612, 0.7442, 0.1842, 1.2895, 1.4737, 0.4211, 0.4556, 1.3222, 1.0000, 0.2444, 0.7714, 2.0000, 1.8286, 0.6286; ... %%
        5, 0.3684, 2.1842, 1.9605, 0.6447, 0.2478, 1.5044, 0.7522, 0.1416, 0.6693, 1.2992, 0.7480, 0.3307, 0.6392, 1.6598, 1.6186, 0.8041; ... %%
        6, 0.5735, 2.7647, 2.2206, 0.6324, 0.2745, 1.6078, 1.2059, 0.4608, 0.6105, 1.7053, 1.3368, 0.4842, 0.6667, 1.8387, 1.7957, 0.9032; ... %%
        7, 0.1150, 0.5752, 0.6106, 0.1770, 0.1690, 1.7606, 1.7606, 0.5915, 0.4000, 0.8417, 1.4667, 1.0917, 0.0329, 0.1842, 0.1842, 0.0724; ... %%
        8, 0.3523, 1.8864, 1.7045, 0.7045, 0.3171, 2.0122, 1.8049, 0.6585, 0.2500, 2.0217, 1.5326, 0.5000, 0.1959, 1.8041, 1.7320, 0.8041; ... %%
        9, 0.3438, 1.2812, 1.2188, 0.3854, 0.4368, 1.6667, 1.9080, 0.8851, 0.2316, 2.0526, 1.3789, 0.3789, 0.2000, 1.7333, 1.7333, 0.5889; ... %%
    ];
    v = calculoVectores(im);
    distancias = sum((aprendidos(:, 2:17) - repmat(v, size(aprendidos, 1) ,1)).^2, 2).^2;
    [d pos] = min(distancias);
    res = aprendidos(pos, 1);
end
% dividimos para cada cuadrante
function [vector] = calculoVectores(im)
    tam = round(size(im) ./ 2);
    v1 = calcularVector(im(1:tam(1), 1:tam(2)));
    v2 = calcularVector(im(1:tam(1), tam(2):size(im, 2)));
    v3 = calcularVector(im(tam(1):size(im, 1), 1:tam(2)));
    v4 = calcularVector(im(tam(1):size(im, 1), tam(2):size(im, 2)));
    vector = [v1, v2, v3, v4];
end
% calculo de un cuadrante
function [vector] = calcularVector(im)
    % metodo que el profe dijo
    % vamos por columnas
    % bajando, subiendo, por izquierda, por derecha
    vector = zeros(1,4);
    % columnas hacia abajo
    for x = 1:size(im, 2)
        for y = 1:size(im, 1)
            if im(y, x) == 1
                vector(1) = vector(1) + y;
                break
            end
        end    
        for y = size(im, 1):-1:1
            if im(y, x) == 1
                vector(2) = vector(2) + y;
                break
            end
        end    
    end
    for y = 1:size(im, 1)
        for x = 1:size(im, 2)
            if im(y, x) == 1
                vector(4) = vector(4) + x;
                break
            end
        end    
        for x = size(im, 2):-1:1
            if im(y, x) == 1
                vector(3) = vector(3) + x;
                break
            end
        end    
    end
    % normalizamos, dividiendo por numero de zeros
    vector = vector ./ numel(find(im == 0));
end

% sacado en parde de la tarea 3 
function [res, xdata, ydata, cajanueva] = homografia(im, pts)
    im = double(im);
    X = pts(:, 1);
    Y = pts(:, 2);
    %  4 -- 3
    %  |    |
    %  1 -- 2
    Xp = [min(X); max(X); max(X); min(X)];
    Yp = [max(Y); max(Y); min(Y); min(Y)];
    im = uint8(im);
    udata = [0 size(im,1)];  vdata = [0 size(im,2)];

    tform = maketform('projective',  [X Y], [Xp Yp]);
    cajanueva = tformfwd(tform, [X Y]);
    [res, xdata, ydata] = imtransform(im, tform);%, 'udata', udata,'vdata', vdata, 'size', size(im));
end