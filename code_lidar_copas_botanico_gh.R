
library(lidR)

mosaico.botanico <- catalog("2catalog_botanico")
plot(mosaico.botanico) # simple scheme of location of datasets 
carbayeda <- clip_circle(mosaico.botanico, 288115, 4821807, radius = 50)
plot(carbayeda, backend="lidRviewer") # default = Z
todo.botanico <- clip_rectangle(mosaico.botanico, 287676,4821673, 288937,4822128)  
plot(todo.botanico, bg="white") 
plot(todo.botanico, backend="lidRviewer")

las_check(todo.botanico) 
str(todo.botanico@data)
summary(todo.botanico$Z)

todo.botanico.norm <- normalize_height(todo.botanico, tin())
summary(todo.botanico.norm$Z)

las_check(todo.botanico.norm)
todo.botanico.norm <- filter_poi(todo.botanico.norm, Z >= 0)
plot(todo.botanico.norm, bg = "white")

dosel.modelo <- rasterize_canopy(todo.botanico.norm, res=1, p2r(subcircle = 0.2), pkg="terra")
plot(dosel.modelo, col = height.colors(50))

fill.na <- function(x, i=5) { if (is.na(x)[i]) { return(mean(x, na.rm = TRUE)) } 
  else { return(x[i]) }}
w <- matrix(1, 3, 3)
dosel.modelo.suave <- terra::focal(dosel.modelo, w, fun = mean, na.rm = TRUE)

plot(dosel.modelo.suave, col = height.colors(50))

copas.p2r.02 <- locate_trees(dosel.modelo.suave, lmf(ws = 10))
plot(dosel.modelo.suave, col = height.colors(50))
plot(sf::st_geometry(copas.p2r.02), add = TRUE, pch = 3)

segmenta <- dalponte2016(dosel.modelo.suave, copas.p2r.02)
copas <- segment_trees (todo.botanico.norm, segmenta)

arboles <- filter_poi(copas, !is.na(treeID))
summary(arboles$Z)
plot(arboles, size = 4, color = "treeID", backend="lidRviewer")

okaliton <- filter_poi(arboles, treeID == 747)
plot(okaliton, size = 6, bg = "white", color = "Z", backend="lidRviewer")
summary(okaliton)
summary(okaliton@data$Z)

Z.media.arbol <- crown_metrics(arboles, func = ~mean(Z))
c <- crown_metrics(arboles, func = ~mean(Z), geom = "convex")

Z.media.arbol$zmedia <- Z.media.arbol$V1
Z.media.arbol$V1 <- NULL
View(Z.media.arbol)

Z.max.arbol <- crown_metrics(arboles, func = ~max(Z))
Z.max.arbol$zmax <- Z.max.arbol$V1
Z.max.arbol$V1 <- NULL

Z.sd.arbol <- crown_metrics(arboles, func = ~sd(Z))
Z.sd.arbol$zsd <- Z.sd.arbol$V1
Z.sd.arbol$V1 <- NULL

n.retornos <- crown_metrics(arboles, func = ~length(ReturnNumber))
n.retornos$nretornos <- n.retornos$V1
n.retornos$V1 <- NULL

arboles.metrica <- cbind(Z.media.arbol, Z.max.arbol, Z.sd.arbol, n.retornos)
arboles.metrica <- arboles.metrica[,c(1,2,4,6,8,9)]
head(arboles.metrica)

arboles.metrica.2 <- crown_metrics(arboles, func = .stdmetrics)

parcelas <- sf::st_read("parcelas.shp", quiet = TRUE)
metricas <- plot_metrics(todo.botanico.norm, func = .stdmetrics, parcelas, radius = 20)
head(metricas)
