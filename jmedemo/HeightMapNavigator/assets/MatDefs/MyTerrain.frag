uniform sampler2D m_Alpha;
uniform sampler2D m_Alpha_2;
uniform sampler2D m_Tex1;
uniform sampler2D m_Tex2;
uniform sampler2D m_Tex3;
uniform sampler2D m_Tex4;
uniform sampler2D m_Tex5;
uniform float m_Tex1Scale;
uniform float m_Tex2Scale;
uniform float m_Tex3Scale;
uniform float m_Tex4Scale;
uniform float m_Tex5Scale;

varying vec2 texCoord;

#ifdef TRI_PLANAR_MAPPING
  varying vec4 vVertex;
  varying vec3 vNormal;
#endif

void main(void)
{
    vec4 outColor;
    vec4 tex1;
    vec4 tex2;
    vec4 tex3;
    vec4 tex4;
    vec4 tex5;

    // get the alpha value at this 2D texture coord
    vec4 alpha   = texture2D( m_Alpha, texCoord.xy );
    vec4 alpha2   = texture2D( m_Alpha_2, texCoord.xy );

#ifdef TRI_PLANAR_MAPPING
    // tri-planar texture bending factor for this fragment's normal
    vec3 blending = abs( vNormal );
    blending = (blending -0.2) * 0.7;
    blending = normalize(max(blending, 0.00001));      // Force weights to sum to 1.0 (very important!)
    blending /= (blending.x + blending.y + blending.z ).xxx;

    // texture coords
    vec4 coords = vVertex;

    vec4 col1 = texture2D( m_Tex1, coords.yz * m_Tex1Scale );
    vec4 col2 = texture2D( m_Tex1, coords.xz * m_Tex1Scale );
    vec4 col3 = texture2D( m_Tex1, coords.xy * m_Tex1Scale );
    // blend the results of the 3 planar projections.
    tex1 = col1 * blending.x + col2 * blending.y + col3 * blending.z;

    col1 = texture2D( m_Tex2, coords.yz * m_Tex2Scale );
    col2 = texture2D( m_Tex2, coords.xz * m_Tex2Scale );
    col3 = texture2D( m_Tex2, coords.xy * m_Tex2Scale );
    // blend the results of the 3 planar projections.
    tex2 = col1 * blending.x + col2 * blending.y + col3 * blending.z;

    col1 = texture2D( m_Tex3, coords.yz * m_Tex3Scale );
    col2 = texture2D( m_Tex3, coords.xz * m_Tex3Scale );
    col3 = texture2D( m_Tex3, coords.xy * m_Tex3Scale );
    // blend the results of the 3 planar projections.
    tex3 = col1 * blending.x + col2 * blending.y + col3 * blending.z;

#else
	tex1    = texture2D( m_Tex1, texCoord.xy * m_Tex1Scale ); // Tile
	tex2    = texture2D( m_Tex2, texCoord.xy * m_Tex2Scale ); // Tile
	tex3    = texture2D( m_Tex3, texCoord.xy * m_Tex3Scale ); // Tile
    tex4    = texture2D( m_Tex4, texCoord.xy * m_Tex4Scale ); // Tile
    tex5    = texture2D( m_Tex5, texCoord.xy * m_Tex5Scale ); // Tile
	
#endif

    tex1 *= alpha.r; // Red channel
	tex2 = mix( tex1, tex2, alpha.g ); // Green channel
	outColor = mix( tex2, tex3, alpha.b ); // Blue channel
    outColor = mix( outColor, tex4, alpha2.r); 
    outColor = mix( outColor, tex5, alpha2.g);
	gl_FragColor = outColor;
}