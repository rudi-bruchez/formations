# Nouvelles fonctions

## TRIM

```sql
-- SQL Server 2017
SELECT TRIM('   vvvvv    ')

-- 2022
SELECT TRIM(BOTH '/' FROM '//vvvvv//')
```

## STRING_AGG

```sql
SELECT Nom, STRING_AGG(Prenom, ', ')
FROM Contact.Contact c
GROUP BY Nom

SELECT STRING_AGG(CAST(Nom AS VARCHAR(MAX)), ', ')
   WITHIN GROUP (ORDER BY c.Nom DESC)
FROM (
   SELECT DISTINCT TOP 1000 Nom
   FROM Contact.Contact 
   WHERE Nom NOT LIKE '%''%'
) c
```

## TRANSLATE

```sql
SELECT CONCAT(Titre, ' ', Prenom, ' ', Nom)
FROM Contact.Contact c

SELECT CONCAT_WS(' ', Titre, Prenom, Nom)
FROM Contact.Contact c

SELECT TRANSLATE('économiser fête à plî', 'éêàî', 'eeai')
```

## STRING_SPLIT

```sql
--SET STATISTICS TIME ON

DECLARE @v VARCHAR(MAX) = 'Zuniga, Zullo, Zuliani, Zuccaro, Zouyed, Zouhri, Zivanocic, Zittoun, Zitfel, Zinzula, Zimmermann, Zimmerman, Ziltener, Ziggiotto, Ziegler, Zheng, Zhang, Zezouin, Zettor, Zerouali, Zenari, Zemouche, Zemmam, Zekrini, Zavala, Zarroug, Zarrilli, Zaric, Zarazir, Zappa, Zaoui, Zanutel, Zanos, Zanon, Zanati, Zanardi, Zamora, Zambrano, Zakari, Zajkowski, Zajaczkowski, Zaegel, Zacher, Zaban, Zabaleta, Yvalun, Yu, Yssambour, Yousfi, Young, York, Yoder, Yilmaz, Yeranian, Yefsah, Yazdani, Yates, Yang, Yahyaoui, Yahia, Yagoub, Yabeko, Yaacoub, Wyllie, Wyatt, Wurtz, Wu, Wright, Wrankle, Wouters, Woodward, Woods, Woodard, Wood, Wong, Wolfrom, Wolfe, Wolf, Wojtylo, Wojeez, Wojcik, Wohlwend, Woerly, Wodka, Wise, Winters, Winfrey, Winckel, Winandy, Wiltgen, Wilson, Wilsch, Wilmot, Willis, Williamson, Williams, Willems, Wilkinson, Wilkins, Wilkerson, Wilinski-ziolek, Wiley, Wilcox, Wiggins, Wierniezky, Wiederkehr, Widiez, Wiart, Whitney, Whitehead, White, Whitaker, Wheeler, Weytens, Weyer, Wetzel, Wetterene, West, Wernert, Werner, Werkman, Wenish, Wendling, Welter, Wells, Welfringer, Welch, Weiss, Weingaessel, Weinfeld, Weiller, Weiler, Weile, Weeren, Weeks, Weekers, Wederhake, Weckbrodt, Webster, Webert, Weber, Webb, Weaver, Wawszczyk, Wauters, Wauquier, Watts, Wattel, Watson, Watrin, Watkins, Waterschoot, Waters, Wasson, Washington, Wasels, Wartel, Warren, Warner, Warion, Waringuez, Wargui, Ware, Ward, Wantz, Wang, Walton, Walters, Walter, Walsh, Walravens, Walls, Wallez, Waller, Walle, Wallaert, Wallace, Wall, Walker, Waldmann, Walczak, Wakin, Wagrez, Wagner, Wagener, Waeytens, Waeckerle, Wade, Wachet, Vullierme, Vuillod, Vuillemenot, Vuillemein, Vuillaume, Vuaillat, Vuagnat, Vrijders, Vrignaud, Vouay, Vothien, Vorwerk, Voquier, Volpe, Volle, Volkaert, Volembini, Voldoire, Voiturin, Voisin, Voignier, Voidet, Vlietinck, Vizioz, Vivot, Vivion, Vivier, Vivien-raguet, Vittot, Vittoretto, Vitse, Vissuzaine, Visitthideth, Viscuso, Visbecq, Virgos, Virey, Vipard, Viotte, Viollet, Violle, 
Violier, Violette, Violet, Violas, Vinolas, Vinet, Vincon, Vinclair, Vinches, Vincent, Vincelot, Vinard, Viltard, Vilnet, Vilmot, Villiere, Villeminoz, Villemin, Villemagne, Villegas, Villefourceix, Villechanoux, Ville, Villarreal, Villard, Villar, Villanueva, Villalobos, Villa, Vilatte, Vilars, Vilaplana, Vigroux, Vigneron, Vignelle, Vigne, Vignaud, Vignau, Vigla, Vigier, Vigan, Vieyra, Vieuxvled, Vieux, Vieron, Vielle, Vidot, Vidiani, Vidament, Vidal-soler, Vidallac, Vidal, Vicol, Vichot, Vichon, Vichier, Vibert, Viaud, Viard, Viandier, Viallon, Viallevieille, Viale, Vialatte, Viala, Veysset, Veyret, Veyre, Veyet, Vesic, Verwaerde, Vervoort, Vervest, Vervel, Verstraete, Verschelde, Verrijkt, Verpoorter, Vernoux, Vernon, Verniti, Vernet, Vernerey, Vernay, Vermot, Vermoesen, Verlinden, Verlhac, Verleyen, Verita, Verin, Verians, Verhoeven, Verheyden, Verhaegen, Vergnolle, Vergnerie, Vergeade, Verge, Vereb, Verdot, Verdonck, Verdier, Verdegem, Verchere, Verbeeren, Verbeek, Venuat, Ventura, Venot, Venier, Venet-guerbette, Venet, Venault, Venara, Venant, Veloso, Velleine, Vella, Velez, Velazquez, Velasquez, Velain, Velaidomestry, Vega, Vedel, Vecten, Veche, Veaux, Vazquez, Vauzanges, Vautier, Vaussy, Vauloup, Vaughn, Vaughan, Vaudoux, Vaudaux, Vasta, Vassy, Vasseur, Vasquez, Varon, Varnier, Varlet, Varin, Vargas, Varez, Varela, Vaquier, Vaquette, Vaquand, Vanzeune, Vanvorde, Vanvooren, Vanuxem, Vansteenkiste, Vansteenkeste, Vanpeene, Vanoost, Vannier, Vanneuville, Vannarien, Vanmaldergem, Vaniglia, Vanhuys, Vanhalme, Vanhaecke, Vang, Vanel, Vanec, Vandiest, Vandiedonck, Vandeweghe, Vandevelde, Vanderstraeten, Vandermaesen, Vander, Vandeputte, Vandenbulcke, Vandenbroucke, Vandenbroeck, Vandenbosse, Vandenberghe, Vandecraen, Vande, Vance, Vanblaere, Vanaken, Valverde, Valot, Valor, Valmaro, Vallon, Vallin, Vallier, Valley, Vallet, Vallernaud, Vallee, Vallas, Vallart, Valla, Valette, Valetta, Valery, Valero, Valenzuela, Valenza, Valenty, Valentine, Valentin, Valencia, Vald
jii, Valdez, Valat, Vaillier, Vaillant, Vaillagou, Vahedi, Vagniez-simonneau, Vagenende, Vaerman, Vachet, Vacher, Vacca, Uveyik, Useldinger, Ursulet, Ursenbach, Urrutiguier, Urquijo, Urbain, Unfer, Underwood, Umuhoza, Ulrich, Uhlmann, Tytgat, Tyrakowski, Tyler, Tyberghien, Tusek, Turpin, Turner, Turlot, Turicik, Turck, Tupin, Tucker, Tubert, Tsilavis, Tsigounis, Tsiete, Tryer, Trupel, Truong, Trump, Trujillo, Truijen, Truffier, Truffert, Truelle, Truck, Truchet, Truc, Trouve, Trousselle, Trousselier, Trouille, Trotta, Trosseau, Tropini, Tropee, Tropamer, Tronche, Tronc, Trompille, Trompette, Trognon, Trochain, Trocellier, Trividic, Tritz, Triquenaux, Triouleyre, Trinquier, Trinh, Trindade, Trincot, Trillaud, Trigano, Tridon, Tricquet, Tricot, Trichet, Tribel, Triaud, Trevino, Treulier, Tressens, Tressard-wilkin, Tresorier, Tresor, Trescarte, Trenier, Tremeac, Tremblay, Trehin, Tregouet, Trebillon, Trebaol, Travis, Trautmann, Trapleti, Tranchemer, Tranchant, Tranchand, Tran, Tramoni, Trachel, Trabelsi, Townsend, Tovoherizo, Touzet-elkanfaoui, Touzet, Toutou, Toutain, Toussaint, Tourres, Tournoux, Tournier, Tourneur, Tourlourat, Tourillon, Tourette, Tourenne, Toupence, Toulouse, Touli, Toulemonde, Touitou, Touillaud, Toueba, Touchot, Touchard, Touchais, Toubeaux, Tostivint, Tossyn, Torte, Tortarolo, Torres, Torchy, Torchet, Toquet, Toppe, Toper, Tonto, Tonon, Tonnieau, Tonnerre, Tonani, Tominez, Tomaszower, Tomas, Todorov, Todd, Tnacheri, Tixier, Titton, Titon, Titin, Tissot, Tissinier, Tissier, Tisserand, Tissaoui, Tissafi, Tison, Tippin, Tintenier, Tinard, Timmers, Timbert, Tilly, Tilhac, Tighilt, Tiers, Tierens, Tientaraboum, Tieghem, Tiebot, Thurel, Thuault, Thuaire, Thoumyre, Thoumelin, Thouard, Thornton, Thorey, Thomy, Thompson, Thomas, Thomann, Tholot, Thollet, Thobois, Thivet, Thiroux, Thirion, Thiriet, Thing, Thilliez, Thillet, Thill, Thijssens, Thieulent, Thiery, Thiercy, Thiellet, Thiebot, Thiebaudt, Thibeaudeau, Thibaut, Thibault, Thezenas, Thevin, Theveny
, Thevenot, Thevenin, Theunis, Thesin, Thery, Therville, Theron, Thercel, Theodose, Theodore, Theodorakis, Thenevin, Thenard, Thebault, Thaureau, Thamiry, Thalmann, Thabourin, Teyssier, Teyssedou, Texier, Texeira, Tevar, Teurtrie, Teulier, Teulet, Tetchan, Tetart, Testeil, Tessier, Tesniere, Tertu, Tertrais, Terry, Terrisse, Terrier, Terrien, Terrell, Terrand, Ternon, Ternisien, Terlecki, Teplitxky, Teodoro, Tendron, Tenaud, Tenani, Tellier, Telle, Teisseire, Teiller, Teigner, Techer, Tebaoui, Tchacondo, Tazeroualti, Taylor, Tavernier, Taverne, Tauzia, Tauvel, Taurant, Taupin, Taton, Tatin, Tate, Tatah, Tasserit, Tartera, Tartarat, Tarquin, Tarle, Tarin, Tardy, Tardivel, Tardiff, Tardi, Tarchini, Taratiel, Taquet, Tapia, Tantot, Tanou, Tanner, Tanic, Tanguy, Tanghe, Tanchoux, Tamrabet, Tambour, Tamayo, Talou, Talneau, Talleu, Tallec, Talhaoui, Taleb, Talbot, Talbault, Talarmain, Takouche, Takenne, Taire, Taillard, Taillade, Taibi, Tahtah, Tahon, Taguengayte, Taghe, Taburiaux, Tabouillot, Tabone, Tabarly, Szwarc, Szpiro, Szpeker, Szlosarczyk, Szlanka, Szambelanczyk, Sylvestre, Sychareunh, Swojak, Sweeney, Swaton, Swanson, Svanfeldt, Sutton, Susek, Surquin, Surply, Summers, Sultan, Sullivan, Sulkowski, Sulikowski, Sukrindro, Sujowski, Suignard, Sugranes, Sueur, Sudol, Subtil, Subra, Subirada, Suarez, Stutzmann, Stuer, Stuart, Stryckmans, Struyve, Struxiano, Strong, Strock, Strickland, Strecker, Straub, Stoven, Stout, Storr, Stornello, Storino, Stori, Stone, Stoltz, Stokes, Stojanovic, Stoikowitch, Stoffyn, Stoefs, Stocklausen, Stieb, Stewart, Stevenson, Stevens, Stern, Sterckman, Stephenson, Stephens, Stephant, Stephan, Stengele, Stelmach, Steiner, Stein, Steiger, Steele, Stecker, Stecken, Stavrides, Staudt, Staskiewicz, Stark, Stara, Stanton, Stanley, Stanic, Stangret, Stancic, Stainmesse, Stafford, Staffe, Staessens, Squalli, Springer, Sprich, Spinau, Spiga, Spielmann, Spick, Spencer, Spence, Spelling, Spears, Sparks, Soyer, Soxhlet, Soury, Sourdois, Soulier, Soulie
, Soulat, Soulan, Souhlal, Souhami, Souffleteau, Soudjambaba, Soude, Soudant, Souchu, Souchon, Souchard, Soubeyran, Soube, Soto, Sotin, Sosa, Sorrentinella, Sorin, Sorel, Sorbier, Sorba, Sontag, Sonor, Sonnet, Sonneraz, Sommier, Solomon, Solocha, Sollier, Solis, Soler, Soldini, Soldano, Solau, Sohier, Sogliuzzo, Soenen, Soedibjo, Socquet, Sochala, Sobrero, Sobngwi, Sobieraj, Soazara, Soares, Snyder, Snow, Sneck, Smolen, Smolders, Smith, Smets, Smeetes, Small, Smagghe, Sluysmans, Slomovits, Slobb, Sloan, Slimani, Skurpel, Skrzypczak, Skoracki, Skinner, Sixdenier, Sivord, Sitta, Sitbon, Sirvent, Sirii, Sirieix, Sireude, Siret, Sirchia, Sinodinos, Sinnaya, Singleton, Singlan, Singh, Siner, Sinama, Sims, Simpson, Simphor, Simova, Simons, Simonnet, Simonneau, Simonian, Simoni, Simonet, Simonelli, Simonel, Simon, Simoes, Simmons, Simic, Simian, Simha, Silvestro, Silvestre, Silve, Silva, Silo-same, Signamarcheix, Sigiscar, Sigalas, Siebert, Sidos, Sidiki, Sidibe, Sidhoum, Sicot, Siciak, Sicari, Sicard, Sibille, Sibella, Short, Shong-wa'

SELECT TRIM(value) 
FROM STRING_SPLIT(@v, ',', 1)
```