Modelos de dosel arbóreo a partir de LiDAR
================
Mario Quevedo
Marzo 2024

## Estructura de la vegetación (arbórea y arbustiva) en el [Jardín Botánico Atlántico de Gijón](https://www.gijon.es/es/directorio/jardin-botanico-atlantico-de-gijon)

(usa ctrl + click para abrir enlaces en una nueva pestaña).

Procedimiento desarrollado con la librería *lidR*, siguiendo en gran
medida las [rutinas descritas por el autor de la
misma](https://github.com/r-lidar/lidR).

``` r
library(lidR)
```

La librería permite leer y escribir los formatos .las y .laz, e incluye
funciones a distinto nivel de organización de datos.

Los datos necesarios para desarrollar este ejemplo son tres archivos
.laz de nubes de puntos LiDAR 3D, [descargados del
IGN](https://centrodedescargas.cnig.es/CentroDescargas/busquedaSerie.do?codSerie=MLID2#).
Cada archivo cubre 2 x 2 km, e incluyen coloración verdadera (RGB).
Están incluidos [en la carpeta comprimida
2catalog_botanico.zip](https://www.dropbox.com/scl/fi/keaer5i67xc6p8toqna9d/2catalog_botanico.zip?rlkey=eb3tmq74au5i71wx3pnnrstdk&dl=0)
El comando `catalog` a continuación construye un mosaico virtual de las
3 coberturas 2 x 2 km:

``` r
mosaico.botanico <- catalog("2catalog_botanico")
```

Un `catalog` es un esquema simple de los datos disponibles, sin ocupar
apenas memoria:

``` r
plot(mosaico.botanico)
```

![](code_lidar_copas_botanico_files/figure-gfm/plot%20mosaico-1.png)<!-- -->

La **extracción** de partes del mosaico se puede realizar con las
distintas funciones `clip`disponibles en **lidR**.

A continuación, dos ejemplos: un fragmento circular de la Carbayeda, y
un rectángulo de datos incluyendo todos los terrenos del Botánico. Las
coordenadas son las originales del conjunto de datos, en este caso UTM
30N. En ambos casos la función `plot` muestra y permite rotar e inclinar
la nube de puntos:

``` r
carbayeda <- clip_circle(mosaico.botanico, 288115, 4821807, radius = 50)
plot(carbayeda) 
```

![](code_lidar_copas_botanico_files/figure-gfm/rgl_carbayeda.png)

``` r
todo.botanico <- clip_rectangle(mosaico.botanico, 287676,4821673, 288937,4822128)  
plot(todo.botanico, bg="white") 
```

![](code_lidar_copas_botanico_files/figure-gfm/rgl_todo_botanico.png)

Los autores de la librería **lidR** (enlace arriba) tienen también un
visor de nubes de puntos mucho más ágil, si bien a diferencia del
estándar requiere cerrar el visor antes de procesar más código R;
requiere la instalación de [la librería adicional
*lidRviewer*](https://github.com/Jean-Romain/lidRviewer):

``` r
plot(todo.botanico, backend="lidRviewer") # default = Z
```

A continuación podemos usar funciones para evaluar la condición general
del conjunto de datos. Concretamente `las_check()` repasa diversos
indicadores interesantes, entre ellos si los datos están normalizados
(más detalle debajo), o si existen muchos puntos duplicados.

``` r
las_check(todo.botanico)
str(todo.botanico@data)
summary(todo.botanico$Z)
```

Esa estadística descriptiva simple se refiere a la variable **Z** de los
datos: la altura de los puntos sobre el nivel del mar, incluyendo el
terreno y la vegetación.

### Normalizando alturas de la vegetación

Para analizr estructura de la vegetación puede ser interesante
**normalizar las nubes de puntos**, eliminando la influencia de la
altura del terreno. Es el cometido de la función`normalize_height`, [que
admite distintos métodos](https://r-lidar.github.io/lidRbook/norm.html).

Tras normalizar los datos podemos aplicar `las_check` de nuevo, así como
repasar la nueva distribución de valores de alturas (Z):

``` r
todo.botanico.norm <- normalize_height(todo.botanico, tin())
```

    ## Delaunay rasterization[=====================================-------------] 74% (2 threads)Delaunay rasterization[=====================================-------------] 75% (2 threads)Delaunay rasterization[======================================------------] 76% (2 threads)Delaunay rasterization[======================================------------] 77% (2 threads)Delaunay rasterization[=======================================-----------] 78% (2 threads)Delaunay rasterization[=======================================-----------] 79% (2 threads)Delaunay rasterization[========================================----------] 80% (2 threads)Delaunay rasterization[========================================----------] 81% (2 threads)Delaunay rasterization[=========================================---------] 82% (2 threads)Delaunay rasterization[=========================================---------] 83% (2 threads)Delaunay rasterization[==========================================--------] 84% (2 threads)Delaunay rasterization[==========================================--------] 85% (2 threads)Delaunay rasterization[===========================================-------] 86% (2 threads)Delaunay rasterization[===========================================-------] 87% (2 threads)Delaunay rasterization[============================================------] 88% (2 threads)Delaunay rasterization[============================================------] 89% (2 threads)Delaunay rasterization[=============================================-----] 90% (2 threads)Delaunay rasterization[=============================================-----] 91% (2 threads)Delaunay rasterization[==============================================----] 92% (2 threads)Delaunay rasterization[==============================================----] 93% (2 threads)Delaunay rasterization[===============================================---] 94% (2 threads)Delaunay rasterization[===============================================---] 95% (2 threads)Delaunay rasterization[================================================--] 96% (2 threads)Delaunay rasterization[================================================--] 97% (2 threads)Delaunay rasterization[=================================================-] 98% (2 threads)Delaunay rasterization[=================================================-] 99% (2 threads)Delaunay rasterization[==================================================] 100% (2 threads)

``` r
summary(todo.botanico.norm$Z)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##  -3.934   0.000   1.001   5.593  10.517  47.398

La nueva descriptiva muestra un valor mínimo negativo. Dado que en los
valores no normalizados de altura no había valores menores de 0, los
valores normalizados negativos son artefactos de la triangulación (asumo
que debidos a bajas densidades de puntos “suelo”, pero no estoy seguro).
En todo caso, podemos prescindir de esos artefactos filtrando los
valores de altura de las nube de puntos normalizada:

``` r
todo.botanico.norm <- filter_poi(todo.botanico.norm, Z >= 0)
## plot(todo.botanico.norm, bg = "white", backend="lidRviewer")
```

### Modelo de alturas del dosel

A continuación elaboramos un modelo de altura del dosel. Será una
cobertura [en formato
ráster](https://docs.qgis.org/3.28/es/docs/gentle_gis_introduction/raster_data.html)
representando los puntos más altos de los retornos, la altura del dosel.
Hay varios algoritmos posobles para obtener esos modelos; el código a
continuación usa \*\*point to
raster\*`**, especificado en`p2r()`, donde el argumento`subcircle =
0.2\` reemplaza cada punto con un disco de radio conocido (20 cm),
minimizando los blancos:

``` r
dosel.modelo <- rasterize_canopy(todo.botanico.norm, res=1, p2r(subcircle = 0.2), pkg="terra")
plot(dosel.modelo, col = height.colors(50))
```

![](code_lidar_copas_botanico_files/figure-gfm/modelo%20dosel-1.png)<!-- -->

### Suavizado del modelo - rellenando blancos

A continuación procesamos el modelo de altura del dosel para suavizarlo,
y rellenar blancos restantes. Las dos primeras líneas de código a
continuación definen la función de suavizado, mientras que la 3ª lo
lleva a cabo a través de la librería de manipulación ráster **terra**.
La última línea exporta el ráster a un archivo GeoTiff - también vía
**terra** - dejándolo disponible para usos en GIS:

``` r
fill.na <- function(x, i=5) { if (is.na(x)[i]) { return(mean(x, na.rm = TRUE)) } 
  else { return(x[i]) }}
w <- matrix(1, 3, 3)
dosel.modelo.suave <- terra::focal (dosel.modelo, w, fun = mean, na.rm = TRUE)
terra::writeRaster(dosel.modelo.suave, "dosel.modelo.tif", overwrite=T)
```

### Detección de árboles

*lmf 2 chm*

``` r
copas.p2r.02 <- locate_trees(dosel.modelo.suave, lmf(ws = 10))
## plot(dosel.modelo.suave, col = height.colors(50))
## plot(sf::st_geometry(copas.p2r.02), add = TRUE, pch = 3)
```

### Segmentación de los árboles detectados

**EXPLICAR…**

``` r
segmentos <- dalponte2016(dosel.modelo.suave, copas.p2r.02)
copas <- segment_trees (todo.botanico.norm, segmentos)
```

``` r
arboles <- filter_poi(copas, !is.na(treeID))
summary(arboles$Z)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##   0.000   3.488   9.342   9.781  15.133  47.398

``` r
plot(arboles, bg = "white", size = 4, color = "treeID")
```

<figure>
<img src="code_lidar_copas_botanico_files/figure-gfm/arboles.png"
alt="Árboles individualizados" />
<figcaption aria-hidden="true">Árboles individualizados</figcaption>
</figure>

### Extrayendo árboles individuales

``` r
okaliton <- filter_poi(arboles, treeID == 747)
plot(okaliton, size = 6, bg = "black")
```

<figure>
<img src="code_lidar_copas_botanico_files/figure-gfm/rgl_okaliton.png"
alt="Nube de puntos correspondiente al gran Eucaliptus globulus situado al SE del Botánico" />
<figcaption aria-hidden="true">Nube de puntos correspondiente al gran
Eucaliptus globulus situado al SE del Botánico</figcaption>
</figure>

Una vez extraidos, esos modelos individuales de árboles son nubes de
datos, de las que podemos extraer información de la manera habitual:
`summary()` nos puede devolver información sobre la propia nube de
puntos, y sobre variables concretas en ella, como la altura (Z).

``` r
## summary(okaliton)
summary(okaliton@data$Z)
```

    ##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    ##    0.00   19.88   34.33   29.65   42.96   47.40

### Extrayendo métricas

- A nivel de árbol

``` r
Z.media.arbol <- tree_metrics(arboles, func = ~mean(Z))
View(Z.media.arbol@data)
n.retornos <- tree_metrics(arboles, func = ~length(ReturnNumber))
View(n.retornos@data)
```

- A nivel de nube de puntos
