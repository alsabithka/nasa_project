# NASA Historical Space Exploration Hardware — Technical Reference Sheet
**GoBot Planetary Exploration Simulator**

This document compiles official NASA technical specifications, engineering blueprints, mechanical subsystem dimensions, materials, scientific payloads, and historical landing coordinates for all 10 spacecraft groups.

---

## PART 1 – MARS SURFACE MACHINERY

### 1. Mars Pathfinder Lander & Sojourner Rover
* **NASA Reference Links:**
  * [Mars Pathfinder Mission](https://science.nasa.gov/mission/mars-pathfinder/)
  * [Sojourner First Images](https://science.nasa.gov/resource/sojourners-first-images-from-mars/)
  * [NASA Photojournal Pathfinder](https://photojournal.jpl.nasa.gov/target/Mars)
* **Landing Site:** Ares Vallis, Chryse Planitia (`19.33° N, 326.45° E` / `33.55° W`)
* **Touchdown Date:** July 4, 1997 (Carl Sagan Memorial Station)
* **Final Status:** Ceased transmission on September 27, 1997 (Sol 83) after battery depletion.

#### Sojourner Microrover Specifications:
* **Dimensions:** Length: `0.65 m` (65 cm), Width: `0.48 m` (48 cm), Height: `0.30 m` (30 cm). Ground clearance: `0.13 m`.
* **Mass:** `11.5 kg` (Earth) / `4.34 kg` (Mars gravity: 3.71 m/s²).
* **Locomotion / Chassis:**
  * 6 independently actuated aluminum wheels with stainless steel cleats/grousers (diameter: `0.13 m`, width: `0.07 m`).
  * 6-wheel articulated rocker-bogie suspension system without springs, distributing weight equally.
  * Maximum speed: `0.01 m/s` (1 cm/s).
* **Power:**
  * Gallium Arsenide (GaAs) solar array panel on top deck (`0.22 m²`), generating peak `16 W` sunlight.
  * Backup primary non-rechargeable lithium thionyl chloride (LiSOCl2) batteries (150 Wh).
* **Instrumentation & Electronics:**
  * Alpha Proton X-ray Spectrometer (APXS) mounted on rear deployment mechanism for elemental rock composition.
  * Forward stereo monochrome CCD camera pair and rear color CCD camera.
  * 3 laser stripers for active autonomous hazard obstacle avoidance.
  * UHF radio whip antenna for communicating with the Pathfinder lander base station.
  * Warm Electronics Box (WEB) insulated with silica aerogel and radioisotope heater units (RHUs).
* **Final Resting Condition:** Inactive, stationary resting on Ares Vallis regolith ~3 meters from the lander facing "Yogi" rock. Coated in a delicate layer of oxidized ferric Martian dust.

#### Mars Pathfinder Lander (Carl Sagan Memorial Station):
* **Dimensions:** Tetrahedron structure standing `0.90 m` tall; petals unfold to a ground footprint diameter of `2.75 m`.
* **Mass:** `264 kg` lander dry mass (`360 kg` landed mass including Sojourner; `890 kg` at entry).
* **Mechanical Structure:**
  * Three triangular composite petals hinged to a central triangular base station.
  * Petals covered with `5.6 m²` of silicon solar cells generating `1,200 Wh/sol`.
  * Dual rollout deployer ramps (woven Kevlar tracks) extending from the petal to the surface.
  * Deflated airbags (vectran fabric) bundled beneath and around the petals.
* **Instrumentation:**
  * Imager for Mars Pathfinder (IMP): Stereo color camera on a deployable 0.8m mast.
  * Atmospheric Structure Instrument / Meteorology package (ASI/MET): 1.1m mast with thermocouples and wind sensors.
  * High-Gain parabolic dish antenna (X-band) and low-gain omnidirectional antenna.

---

### 2. Mars Exploration Rovers: Spirit (MER-A) & Opportunity (MER-B)
* **NASA Reference Links:**
  * [MER Spirit](https://science.nasa.gov/mission/mer-spirit/)
  * [MER Opportunity](https://science.nasa.gov/mission/mer-opportunity/)
  * [MER Technical Diagrams](https://science.nasa.gov/mission/mars-exploration-rovers-spirit-and-opportunity/)
* **Landing Dates:**
  * Spirit: January 4, 2004
  * Opportunity: January 25, 2004

#### Physical Dimensions & Mechanics:
* **Dimensions:** Length: `1.60 m`, Width: `2.30 m` (across deployed solar wings), Height: `1.50 m` (to top of Pancam mast).
* **Mass:** `185 kg` per rover.
* **Chassis & Suspension:**
  * Titanium and composite rocker-bogie suspension system with differential crossbar.
  * 6 aluminum wheels (diameter: `0.26 m`) with spiral flexure spokes and machined outer spiral tread grousers.
  * In-wheel individual DC brushless drive motors and steer motors on front and rear corners.
* **Upper Deck & Electronics:**
  * Multi-junction triple-junction solar array wings (`1.3 m²`, generating peak `140 W` to `900 Wh/sol`).
  * Pancam Mast Assembly (PMA): Extends 1.5m above ground, carrying Panoramic Cameras (Pancam) and Navigation Cameras (Navcam).
  * High-Gain steerable dish antenna (diameter: `0.28 m`) and omnidirectional UHF low-gain antenna.
  * Insulated Warm Electronics Box (WEB) with gold-plated exterior, housing 20 MHz RAD6000 CPU and Li-ion batteries.
* **Instrument Deployment Device (IDD / Robotic Arm):**
  * 5-degree-of-freedom titanium articulated arm (`0.85 m` reach) carrying the scientific turret:
    * Microscopic Imager (MI): High-resolution extreme close-up surface texture camera.
    * Mössbauer Spectrometer (MB): Iron-bearing mineral oxidation state identifier.
    * Alpha Particle X-ray Spectrometer (APXS): Elemental chemistry sensor.
    * Rock Abrasion Tool (RAT): High-speed diamond-matrix grinding wheel with wire brushes.

#### Final resting locations & historical conditions:
* **Spirit (MER-A):**
  * **Location:** Gusev Crater / Columbia Hills ("Troy" plateau, western slope of Home Plate): `14.5684° S, 175.4726° E`.
  * **Final Condition:** Embedded in soft sulfate-rich sand at Troy since Sol 1892 (May 2009). Right-front wheel seized and dragged. Last signal received March 22, 2010. Faded and heavily dust-mantled solar deck.
* **Opportunity (MER-B):**
  * **Location:** Meridiani Planum / Western rim of Endeavour Crater ("Perseverance Valley"): `1.95° S, 354.47° E` (`5.53° W`).
  * **Final Condition:** Positioned on the downward slope of Perseverance Valley. Survived 14.5 years and 45.16 km of traverse before the global planet-encircling dust storm of June 2018 depleted solar power. Last transmission received June 10, 2018 (Sol 5111). Solar array covered in a matte mantle of fine dust, arm parked.

---

### 3. Viking 1 & Viking 2 Landers
* **NASA Reference Links:**
  * [Viking 1](https://science.nasa.gov/mission/viking-1/)
  * [Viking 2](https://science.nasa.gov/mission/viking-2/)
  * [Viking Mission Resources](https://science.nasa.gov/mars/resources/viking-mission-resources/)
* **Landing Sites:**
  * **Viking 1:** Chryse Planitia (`22.27° N, 312.05° E` / `47.95° W`) — Touchdown: July 20, 1976. Final signal: November 11, 1982.
  * **Viking 2:** Utopia Planitia (`47.97° N, 134.29° E` / `225.71° W`) — Touchdown: September 3, 1976. Final signal: April 11, 1980.

#### Technical Specifications:
* **Dimensions:** Hexagonal main body width: `1.50 m` across flats; height: `2.10 m` (to top of S-band dish); landing leg span: `3.00 m` footpad to footpad.
* **Mass:** `612 kg` landed dry mass on Mars (`572 kg` empty).
* **Structure & Landing System:**
  * Titanium and 7075 aluminum monocoque hexagonal platform.
  * Three deployable landing legs with honeycomb crushable aluminum strut shock absorbers and circular footpads (`0.30 m` diameter).
  * Three hydrazine terminal descent monopropellant rocket engines with 18-nozzle showerhead diffusers beneath chassis.
* **Power System (NON-SOLAR):**
  * Two SNAP-19 Radioisotope Thermoelectric Generators (RTGs) containing Plutonium-238, mounted in dual cylindrical thermal radiator wind-screens on the top deck (`57 W` continuous electrical power). NO solar panels.
* **Scientific Payload & Manipulators:**
  * Surface Sampler Boom: `3.0 m` telescoping robotic arm with backhoe scoop, vibrator sieve, and temperature sensor.
  * Gas Chromatograph Mass Spectrometer (GCMS) and Biology experiment soil processing funnel.
  * Meteorology boom carrying wind speed sensors, thermocouple, and pressure transducer.
  * Two Facsimile Scanning Cameras mounted on elevated masts at opposite sides of the top deck.
  * S-band high-gain parabolic steerable dish antenna (`0.76 m` diameter) and bi-conical UHF antenna.
* **Final Condition:** Intact, weathered aluminum with oxidized reddish soil splatters, RTG housings showing slight thermal discoloration, sampler arm resting on the regolith trench.

---

### 4. Phoenix Mars Lander
* **NASA Reference Links:**
  * [Phoenix Mars Mission](https://science.nasa.gov/mission/mars-phoenix/)
* **Landing Site:** Vastitas Borealis ("Green Valley"): `68.22° N, 234.25° E` (`125.75° W`)
* **Touchdown Date:** May 25, 2008
* **Final Status:** Ceased transmission November 2, 2008 as high-latitude polar winter sunlight waned and dry-ice frost formed.

#### Technical Specifications:
* **Dimensions:** Main deck width: `1.50 m`; height: `2.20 m` with mast deployed; solar wing span: `5.52 m` tip to tip.
* **Mass:** `350 kg` landed mass.
* **Power System:**
  * Two circular 10-sided decagonal deployed solar array wings (diameter: `2.09 m` each), producing up to `750 Wh/sol`.
* **Robotic Arm & Excavation System:**
  * Robotic Arm (RA): `2.35 m` 4-degree-of-freedom articulated arm equipped with a tungsten carbide rasp blade and scoop for penetrating rock-hard subsurface water-ice permafrost.
  * Robotic Arm Camera (RAC) with dual LED illuminators mounted directly above the scoop.
* **Deck Instruments:**
  * Thermal and Evolved Gas Analyzer (TEGA): 8 miniature ovens for vaporizing ice and soil samples.
  * Microscopy, Electrochemistry, and Conductivity Analyzer (MECA).
  * Surface Stereo Imager (SSI) on vertical mast.
  * Canadian Space Agency Meteorological Station (MET) with lidar laser sounding and temperature sensors.
* **Final Condition:** Surrounded by polygonally patterned permafrost ground; solar panels experienced severe polar CO2 ice accumulation and structural frost fatigue during Martian winter.

---

### 5. InSight Mars Lander
* **NASA Reference Links:**
  * [InSight Spacecraft](https://science.nasa.gov/mission/insight/spacecraft/)
  * [InSight Mission](https://science.nasa.gov/mission/insight/)
* **Landing Site:** Elysium Planitia (`4.50° N, 135.62° E`)
* **Touchdown Date:** November 26, 2018
* **Final Status:** Retired December 21, 2022 following extensive dust accumulation on solar arrays.

#### Technical Specifications:
* **Dimensions:** Deck diameter: `1.56 m`; height: `1.08 m`; total width across deployed solar arrays: `6.00 m`.
* **Mass:** `358 kg` landed dry mass.
* **Power System:**
  * Two deployable 10-sided circular decagonal UltraFlex solar arrays (diameter: `2.15 m` each). Initial output: `4.5 kWh/sol`, reduced to `< 500 Wh/sol` after 4 years of dust accumulation.
* **Scientific Payloads:**
  * **SEIS (Seismic Experiment for Interior Structure):** 6-sensor ultra-sensitive seismometer deployed onto the Martian ground, enclosed beneath an aerodynamic Wind and Thermal Shield (WTS) dome (`0.69 m` diameter, gold thermal reflective foil). Connected to the lander by a flat flexible ribbon cable.
  * **HP3 (Heat Flow and Physical Properties Package):** Known as "The Mole", designed to hammer down 5m. Encountered unexpected friction soil anomalies and halted near surface (`0.37 m` depth). Remains adjacent to the lander with support structure.
  * **Instrument Deployment Arm (IDA):** `1.80 m` robotic arm with a motorized five-claw wax-actuated grapple.
  * **RISE (Rotation and Interior Structure Experiment):** Dual X-band horn antennas on top deck.
  * **TWINS (Temperature and Winds for InSight):** Dual mast-mounted weather sensors.
* **Final Condition:** Stationary on smooth sandy volcanic plain, solar wings covered in dark ochre dust, SEIS protective dome firmly seated on the ground with ribbon cable visible.

---

### 6. Ingenuity Mars Helicopter
* **NASA Reference Links:**
  * [Ingenuity Mars Helicopter](https://science.nasa.gov/mission/mars-2020-perseverance/ingenuity-mars-helicopter/)
* **Operating Site:** Jezero Crater ("Wright Brothers Field" to "Valinor Hills"): `18.44° N, 77.45° E`
* **First Flight:** April 19, 2021 | **Final Flight (Flight 72):** January 18, 2024
* **Final Status:** Retired January 25, 2024 after sustaining tip blade damage on Flight 72 at Valinor Hills.

#### Technical Specifications:
* **Dimensions:**
  * Rotor System Diameter: `1.21 m` (47.6 inches).
  * Fuselage Body: `0.195 m` length × `0.163 m` width × `0.136 m` height (box size ~17 × 14 × 14 cm).
  * Total Height: `0.49 m` (from landing footpads to top of solar panel).
* **Mass:** Exactly `1.80 kg` (4.0 lbs on Earth) / `0.68 kg` on Mars.
* **Rotor Assembly:**
  * Dual counter-rotating coaxial carbon-fiber foam-core blades (upper and lower pairs).
  * High-speed rotation rate: `2,400 to 2,700 RPM` to generate lift in Mars's 1% Earth atmospheric density (~6.1 hPa).
  * Collective swashplate assemblies actuated by miniature servomotors.
* **Fuselage & Legs:**
  * Four splayed carbon-composite landing legs (length: `0.384 m`) with shock-absorbing flexures.
  * Lightweight aluminum frame with purple/gold thermal Kapton insulation.
  * Solar Array: Rectangular photovoltaic panel (`0.06 m²`) mounted directly above the coaxial rotor head.
  * Battery: 6 Sony Li-ion cells (35.7 Wh capacity) providing 350W peak propulsion power.
  * Avionics: Qualcomm Snapdragon 801 processor, downward-facing laser rangefinder, and high-resolution downward color terrain camera.
* **Final Documented Condition:** Standing upright on all four legs on a low sand ripple at Valinor Hills. Three rotor blades intact; one blade tip fractured ~15 cm from end during hard landing, with minor damage to opposite blade counterweight.

---

## PART 2 – SPACECRAFT FROM OTHER DESTINATIONS
*(Separately cataloged for Solar System collection / Orbital Museum mode — not placed on Mars surface)*

### 7. Dawn Spacecraft
* **NASA Reference Links:**
  * [Dawn Spacecraft Technology](https://science.nasa.gov/mission/dawn/technology/spacecraft/)
  * [Dawn Multimedia Images](https://science.nasa.gov/mission/dawn/multimedia/images/)
* **Target Destinations:** Asteroid 4 Vesta (2011–2012) and Dwarf Planet 1 Ceres (2015–2018).
* **Current Status:** Inactive, derelict in stable perpetual orbit around Ceres. Final signal: November 1, 2018.

#### Technical Specifications:
* **Dimensions:**
  * Spacecraft Core Body: `1.64 m` length × `1.27 m` width × `1.77 m` height.
  * Total Wingspan (Solar Arrays Deployed): `19.70 m` tip to tip.
  * High-Gain Antenna (HGA): `1.52 m` diameter parabolic reflector dish.
* **Mass:** `1,217.7 kg` launch mass (`747.1 kg` dry mass).
* **Propulsion System:**
  * Three 30-centimeter NSTAR Xenon Ion Thrusters (gimballed), generating 19–91 mN thrust with Isp of 3,100 seconds.
* **Power System:**
  * Two massive 5-panel rectangular solar arrays (`36.4 m²` total area), producing 10.3 kW at 1 AU and 1.3 kW at Ceres (3 AU).
* **Scientific Instruments:**
  * Dual Framing Cameras (FC), Visible and Infrared Mapping Spectrometer (VIR), Gamma Ray and Neutron Detector (GRaND).

---

### 8. NEAR Shoemaker (Near Earth Asteroid Rendezvous)
* **NASA Reference Links:**
  * [NEAR Shoemaker](https://science.nasa.gov/mission/near-shoemaker/)
  * [PDS NEAR Technical Context](https://pds.nasa.gov/ds-view/pds/viewContext.jsp?identifier=urn%3Anasa%3Apds%3Acontext%3Ainstrument_host%3Aspacecraft.near&version=1.3)
* **Destination:** Asteroid 433 Eros.
* **Touchdown Date:** February 12, 2001 (historic first landing on an asteroid). Final signal: February 28, 2001.

#### Technical Specifications:
* **Dimensions:**
  * Main Bus: Octagonal prism `1.70 m` on each side, standing `2.80 m` tall including the antenna.
  * Solar Panels: Four fixed GaAs solar panels (`1.80 m × 1.20 m` each) arranged in a distinct 4-blade "windmill" cross pattern.
  * High-Gain Antenna: Fixed `1.50 m` diameter parabolic X-band dish mounted coaxially.
* **Mass:** `805 kg` launch mass (`487 kg` dry mass).
* **Landing Configuration:**
  * NEAR Shoemaker had NO landing legs. It rested gently on the southern tip of its four windmill solar panels and main lower chassis ring on the regolith of Eros at `0.19 m/s` impact velocity.
* **Payload:**
  * Multispectral Imager (MSI), X-ray/Gamma-Ray Spectrometer (XGRS), Near-Infrared Spectrometer (NIS), Laser Rangefinder (NLR), and Magnetometer mounted on a 1.2m boom.

---

### 9. Pioneer 10 & Pioneer 11 Probes
* **NASA Reference Links:**
  * [Pioneer 10 Mission](https://science.nasa.gov/mission/pioneer-10/)
  * [Pioneer Spacecraft Diagram](https://science.nasa.gov/resource/pioneer-spacecraft-diagram/)
* **Targets & Trajectories:**
  * Pioneer 10: First mission to Jupiter (Dec 1973), traversing the Asteroid Belt; hyperbolic escape trajectory out of Solar System towards Aldebaran. Final signal: January 23, 2003 (80 AU from Earth).
  * Pioneer 11: First mission to fly past Saturn (Sept 1979) and Jupiter; hyperbolic escape trajectory towards constellation Aquila. Final signal: November 30, 1995.

#### Technical Specifications:
* **Dimensions:**
  * High-Gain Antenna Dish: `2.74 m` (9.0 feet) diameter parabolic parabolic dish reflector.
  * Main Equipment Compartment: Hexagonal bus, `0.36 m` deep, `0.76 m` width on each side.
  * Overall Length: `2.90 m` from feed horn to rear thruster cluster.
  * Magnetometer Boom: `6.60 m` deployable lattice boom extending radially outward.
* **Mass:** `258 kg` launch mass.
* **Power System (NON-SOLAR):**
  * Four SNAP-19 Radioisotope Thermoelectric Generators (RTGs) mounted in pairs on two extended trusses (`3.0 m` length) angled 120° apart, generating 155W at launch. NO solar panels.
* **Distinctive Features:**
  * The famous gold-anodized aluminum Pioneer Plaque (`229 mm × 152 mm × 1.27 mm`) engraved with figures of human beings and pulsar navigation map, attached to the antenna support struts.

---

### 10. Kepler Space Telescope
* **NASA Reference Links:**
  * [Kepler Mission](https://science.nasa.gov/mission/kepler/)
  * [Kepler Spacecraft Diagram](https://science.nasa.gov/resource/kepler-spacecraft/)
* **Orbit:** Earth-trailing heliocentric orbit (period ~372 days).
* **Mission History:** Launched March 7, 2009; discovered >2,600 confirmed exoplanets; retired October 30, 2018 upon fuel exhaustion.

#### Technical Specifications:
* **Dimensions:**
  * Total Length / Height: `4.70 m` (15.4 feet).
  * Width: `2.70 m` (8.9 feet) diameter across hexagonal bus and solar arrays.
  * Telescope Aperture: `0.95 m` diameter Schmidt-type photometer with fused silica corrector plate.
  * Primary Mirror: `1.40 m` diameter ultra-lightweight honeycomb borosilicate mirror.
* **Mass:** `1,052.4 kg` launch mass (`1,040.7 kg` dry mass).
* **Power System:**
  * Curved solar array mounted to the sunward exterior baffle of the telescope tube (`10.2 m²`), producing `1,100 W`.
* **Focal Plane & Instrumentation:**
  * Array of 42 CCDs (`95 megapixels` total) covering a 115 square degree field of view in Cygnus and Lyra.
  * Steerable high-gain parabolic antenna for Ka-band scientific telemetry.
  * Reaction wheel compartment at base for milli-arcsecond pointing stability.
* **Final Status:** Drifting silently in deep space in an Earth-trailing solar orbit.

---

## PART 3 – GEOGRAPHICAL MAPPING MATRIX ON SPHERICAL MARS

| Machine Name | Spacecraft Type | Historical Location | Latitude | Longitude (East) | Surface State |
|---|---|---|---|---|---|
| **Sojourner** | Micro-Rover | Ares Vallis | `19.33° N` | `326.45° E` | Stationary on regolith ~3m from lander |
| **Pathfinder** | Deployed Lander | Ares Vallis | `19.33° N` | `326.45° E` | 3 petals open, airbags deflated, IMP mast erect |
| **Spirit (MER-A)** | Rover | Gusev Crater (Troy) | `14.57° S` | `175.47° E` | Sand-embedded at Troy, right-front wheel seized |
| **Opportunity (MER-B)** | Rover | Meridiani (Perseverance Valley) | `1.95° S` | `354.47° E` | Western rim slope of Endeavour, dust-mantled |
| **Viking 1** | Stationary Lander | Chryse Planitia | `22.27° N` | `312.05° E` | 3 legs on regolith, RTG shrouds, trench arm |
| **Viking 2** | Stationary Lander | Utopia Planitia | `47.97° N` | `134.29° E` | 3 legs on rock field, RTG shrouds, sampler boom |
| **Phoenix** | Stationary Lander | Vastitas Borealis | `68.22° N` | `234.25° E` | Polygonal permafrost, circular solar wings |
| **InSight** | Stationary Lander | Elysium Planitia | `4.50° N` | `135.62° E` | 2 decagonal wings, SEIS dome & cable on ground |
| **Ingenuity** | Coaxial Helicopter | Jezero Crater (Valinor Hills) | `18.44° N` | `77.45° E` | Upright on 4 legs, 1 damaged blade tip |
