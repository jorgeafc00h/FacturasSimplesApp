//
//  Emisor.swift
//  App
//
//  Created by Jorge Flores on 11/17/24.
//
import Foundation
import SwiftData

@Model
class Emisor{
    var id: Int
    var nit: String
    var nrc: String
    var nombre: String
    var codActividad: String
    var descActividad: String
    var nombreComercial: String
    var tipoEstablecimiento: String
    
    var telefono: String
    var correo: String
    var codEstableMH: String
    var codEstable: String
    var codPuntoVentaMH: String
    var codPuntoVenta: String
    
    // Dirección
    var departamento: String
    var municipio: String
    var complemento: String
     
    
    init(
        id: Int = 0,
        nit: String = "",
        nrc: String = "",
        nombre: String = "",
        codActividad: String = "",
        descActividad: String = "",
        nombreComercial: String = "",
        tipoEstablecimiento: String = "",
        telefono: String = "",
        correo: String = "",
        codEstableMH: String = "",
        codEstable: String = "",
        codPuntoVentaMH: String = "",
        codPuntoVenta: String = "",
        departamento: String = "",
        municipio: String = "",
        complemento: String = ""
    ) {
        self.id = id
        self.nit = nit
        self.nrc = nrc
        self.nombre = nombre
        self.codActividad = codActividad
        self.descActividad = descActividad
        self.nombreComercial = nombreComercial
        self.tipoEstablecimiento = tipoEstablecimiento
        self.telefono = telefono
        self.correo = correo
        self.codEstableMH = codEstableMH
        self.codEstable = codEstable
        self.codPuntoVentaMH = codPuntoVentaMH
        self.codPuntoVenta = codPuntoVenta
        self.departamento = departamento
        self.municipio = municipio
        self.complemento = complemento
    }
    
 
   
    // Preview helper
    static var preview: Emisor {
        Emisor(
            id: 1,
            nit: "0614-130687-101-0",
            nrc: "12345-6",
            nombre: "Empresa de Ejemplo, S.A. de C.V.",
            codActividad: "12345",
            descActividad: "Venta al por menor",
            nombreComercial: "Empresa Ejemplo",
            tipoEstablecimiento: "Sucursal",
            telefono: "2222-2222",
            correo: "ejemplo@empresa.com",
            codEstableMH: "EST001",
            codEstable: "SUC001",
            codPuntoVentaMH: "PV001",
            codPuntoVenta: "CAJA01",
            departamento: "San Salvador",
            municipio: "San Salvador",
            complemento: "Calle Principal #123, Colonia Centro"
        )
    }
}
