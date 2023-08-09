Shader "BountyBrawl/Dressing/GrassUpgrade"
{
	Properties
	{
		
		[KeywordEnum(Off,Cylindrical,Spherical)] _BillBoardMode("Bill Board Mode", Float) = 0
		_MainTex("Main Texture", 2D) = "white" {}
		_AlphaCutout("Alpha Cutout", Range(0.0, 1.0)) = 0.5
		
		[Header(Wind Animation)]
		[KeywordEnum(Off,On)] _UseWindAnimation("Use WindAnimation", Float) = 1
		_ShakeDisplacement("Displacement", Range(0, 2.0)) = 1.0
		_ShakeTime("Shake Time", Range(0, 2.0)) = 1.0
		_ShakeWindspeed("Shake Windspeed", Range(0, 2.0)) = 1.0
		_ShakeBending("Shake Bending", Range(0, 2.0)) = 1.0
	}

		Category
		{
			SubShader
			{
			LOD 0
				Tags { "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" "PreviewType" = "Plane" }
				//Blend[_SrcBlend][_DstBlend]
				ColorMask RGB
				Cull Back
				Lighting Off
				ZWrite Off

				Pass {

					CGPROGRAM

					#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
					#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
					#endif
					#include "UnityCG.cginc"

					#pragma vertex vert
					#pragma fragment frag
					#pragma target 2.0
					#pragma multi_compile_instancing
					#pragma multi_compile_fog
					
					#pragma shader_feature _BILLBOARDMODE_OFF _BILLBOARDMODE_CYLINDRICAL _BILLBOARDMODE_SPHERICAL
					#pragma shader_feature _USEWINDANIMATION_OFF _USEWINDANIMATION_ON

	

					struct vertexInput
					{				
							float4 vertex : POSITION;
							float4 texcoord : TEXCOORD0;
							fixed4 vertexColor : COLOR;			
						UNITY_VERTEX_INPUT_INSTANCE_ID
					};

					struct vertexOutput
					{
						float4 vertex : SV_POSITION;
						float4 texcoord : TEXCOORD0;
						fixed4 vertexColor : COLOR;

						UNITY_VERTEX_INPUT_INSTANCE_ID
						UNITY_VERTEX_OUTPUT_STEREO

					};

					void FastSinCos(float4 val, out float4 s, out float4 c)
					{
						val = val * 6.408849 - 3.1415927;
						float4 r5 = val * val;
						float4 r6 = r5 * r5;
						float4 r7 = r6 * r5;
						float4 r8 = r6 * r5;
						float4 r1 = r5 * val;
						float4 r2 = r1 * r5;
						float4 r3 = r2 * r5;
						float4 sin7 = { 1, -0.16161616, 0.0083333, -0.00019841 };
						float4 cos8 = { -0.5, 0.041666666, -0.0013888889, 0.000024801587 };
						s = val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;
						c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
					}


					#if UNITY_VERSION >= 560
					UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
					#else
					uniform sampler2D_float _CameraDepthTexture;
					#endif

					//Don't delete this comment
					// uniform sampler2D_float _CameraDepthTexture;

					uniform sampler2D _MainTex;
					uniform float4 _MainTex_ST;
					uniform float _InvFade;
					uniform float _AlphaCutout;

					#if _USEWINDANIMATION_ON	
						uniform float _ShakeDisplacement;
						uniform float _ShakeTime;
						uniform float _ShakeWindspeed;
						uniform float _ShakeBending;
					#endif
		
					vertexOutput vert(vertexInput v)
					{					
						#if _USEWINDANIMATION_ON					
							float factor = (1 - _ShakeDisplacement - v.vertexColor.r) * 0.5;

							float _WindSpeed = (_ShakeWindspeed + v.vertexColor.g);
							float _WaveScale = _ShakeDisplacement;

							float4 _waveXSize = float4(0.048, 0.06, 0.24, 0.096);
							float4 _waveZSize = float4 (0.024, .08, 0.08, 0.2);
							float4 waveSpeed = float4 (1.2, 2, 1.6, 4.8);

							float4 _waveXmove = float4(0.024, 0.04, -0.12, 0.096);
							float4 _waveZmove = float4 (0.006, .02, -0.02, 0.1);

							float4 waves;
							waves = v.vertex.x * _waveXSize;
							waves += v.vertex.z * _waveZSize;

							waves += _Time.x * (1 - _ShakeTime * 2 - v.vertexColor.b) * waveSpeed * _WindSpeed;

							float4 s, c;
							waves = frac(waves);
							FastSinCos(waves, s, c);

							float waveAmount = v.texcoord.y * (v.vertexColor.a + _ShakeBending);
							s *= waveAmount;

							s *= normalize(waveSpeed);

							s = s * s;
							float fade = dot(s, 1.3);
							s = s * s;
							float3 waveMove = float3 (0, 0, 0);
							waveMove.x = dot(s, _waveXmove);
							waveMove.z = dot(s, _waveZmove);
						#endif

						vertexOutput o;
						UNITY_SETUP_INSTANCE_ID(v);
						UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
						UNITY_TRANSFER_INSTANCE_ID(v, o);

						#if _USEWINDANIMATION_ON
							v.vertex.xz -= mul((float3x3)unity_WorldToObject, waveMove).xz;
						#else
							v.vertex.xyz += float3(0, 0, 0);
						#endif

						
						o.vertex = UnityObjectToClipPos(v.vertex);	

						#if _BILLBOARDMODE_CYLINDRICAL
							// The world position of the center of the object
							float3 worldPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
			
							// Distance between the camera and the center
							float3 dist = _WorldSpaceCameraPos - worldPos;
			
							// atan2(dist.x, dist.z) = atan (dist.x / dist.z)
							// With atan the tree inverts when the camera has the same z position
							float angle = atan2(dist.x, dist.z);
			
							float3x3 rotMatrix;
							float cosinus = cos(angle);
							float sinus = sin(angle);
				
							// Rotation matrix in Y
							rotMatrix[0].xyz = float3(cosinus, 0, sinus);
							rotMatrix[1].xyz = float3(0, 1, 0);
							rotMatrix[2].xyz = float3(- sinus, 0, cosinus);
			
							// The position of the vertex after the rotation
							float4 newPos = float4(mul(rotMatrix, v.vertex * float4(1, 1, 0, 0)), 1);
								
							o.vertex = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, newPos));

						#elif _BILLBOARDMODE_SPHERICAL
							float3 vpos = mul((float3x3)unity_ObjectToWorld, v.vertex.xyz);
							float4 worldCoord = float4(unity_ObjectToWorld._m03, unity_ObjectToWorld._m13, unity_ObjectToWorld._m23, 1);
							float4 viewPos = mul(UNITY_MATRIX_V, worldCoord) + float4(vpos, 0);
							float4 outPos = mul(UNITY_MATRIX_P, viewPos);

							o.vertex = outPos;
						
						#endif

			
						o.texcoord = v.texcoord;
						UNITY_TRANSFER_FOG(o,o.vertex);
						return o;
					}

					fixed4 frag(vertexOutput i) : SV_Target
					{
						float2 uv = i.texcoord;
						fixed4 texColor = tex2D(_MainTex, uv.xy * _MainTex_ST.xy + _MainTex_ST.zw);
						float AlphaClipThreshold = _AlphaCutout;

						clip(texColor.a - AlphaClipThreshold);
						fixed4 FinalColor = texColor;
						UNITY_APPLY_FOG(i.fogCoord, FinalColor);
						return FinalColor;
					}
					ENDCG
				}
			}
		}
		CustomEditor "NanuqGrassShaderGUI"

}
