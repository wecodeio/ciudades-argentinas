#!/usr/bin/env ruby

require "open-uri"
require "json"
require "nokogiri"
require "titleize"

class Ciudad < Struct.new(:id, :nombre)
  def to_h
    { id: id, nombre: nombre.titleize }
  end
end

class Provincia
  attr_reader :id, :nombre, :ciudades
  attr_writer :ciudades

  def initialize(id, nombre)
    @id, @nombre = id.to_i, nombre.titleize
    @ciudades = []
  end

  def to_h
    { id: id, nombre: nombre, ciudades: ciudades.map(&:to_h) }
  end
end

doc = Nokogiri::HTML(open("http://www.migraciones.gov.ar/tarjeta/index2TES.php?idioma=ESPA&tar=TES"))

provincias = doc.css("#provincias option").reject { |option| option["value"].empty? }
provincias.map! { |option| Provincia.new(option["value"].to_i, option.text) }

provincias.each do |provincia|
  doc = Nokogiri::HTML(open("http://www.migraciones.gov.ar/tarjeta/ajaxLocalidades.php?provincia=#{provincia.id}"))
  ciudades = doc.css("option")
  provincia.ciudades = ciudades.map { |option| Ciudad.new(option["value"], option.text) }
end

File.open("ciudades-argentinas.json", "w") do |f|
  f << JSON.generate(provincias.map!(&:to_h))
end
