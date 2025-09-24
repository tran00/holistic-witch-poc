import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RagService {
  late final String _pineconeHost;
  late final String _pineconeApiKey;
  late final String _pineconeIndexName;
  late final String _supabaseUrl;
  late final String _supabaseServiceKey;
  late final String _openaiApiKey;
  late final String _embeddingModel;
  late final int _embeddingDimension;

  RagService() {
    _pineconeHost = dotenv.env['PINECONE_HOST'] ?? '';
    _pineconeApiKey = dotenv.env['PINECONE_API_KEY'] ?? '';
    _pineconeIndexName = dotenv.env['PINECONE_INDEX_NAME'] ?? '';
    _supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    _supabaseServiceKey = dotenv.env['SUPABASE_SERVICE_KEY'] ?? '';
    _openaiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    _embeddingModel = dotenv.env['OPENAI_EMBEDDING_MODEL'] ?? 'text-embedding-3-small';
    _embeddingDimension = int.tryParse(dotenv.env['EMBEDDING_DIMENSION'] ?? '1536') ?? 1536;
    
    // Debug configuration on initialization
    _debugConfiguration();
  }

  /// Debug configuration and environment variables
  void _debugConfiguration() {
    print('🔧 RAG Service Configuration:');
    print('  - Pinecone Host: ${_pineconeHost.isNotEmpty ? "✅ Set" : "❌ Missing"}');
    print('  - Pinecone API Key: ${_pineconeApiKey.isNotEmpty ? "✅ Set (${_pineconeApiKey.length} chars)" : "❌ Missing"}');
    print('  - Pinecone Index: ${_pineconeIndexName.isNotEmpty ? "✅ $_pineconeIndexName" : "❌ Missing"}');
    print('  - Supabase URL: ${_supabaseUrl.isNotEmpty ? "✅ Set" : "❌ Missing"}');
    print('  - Supabase Key: ${_supabaseServiceKey.isNotEmpty ? "✅ Set (${_supabaseServiceKey.length} chars)" : "❌ Missing"}');
    print('  - OpenAI Key: ${_openaiApiKey.isNotEmpty ? "✅ Set (${_openaiApiKey.length} chars)" : "❌ Missing"}');
    print('  - Embedding Model: $_embeddingModel');
    print('  - Embedding Dimension: $_embeddingDimension');
  }

    /// Debug method to test Pinecone with different thresholds
  Future<Map<String, dynamic>> debugPineconeSearch(String query) async {
    try {
      print('🔬 DEBUG: Testing Pinecone search with various thresholds');
      
      // Generate embedding
      final queryEmbedding = await generateEmbedding(query);
      print('🔬 Query embedding: ${queryEmbedding.take(3).toList()}... (${queryEmbedding.length} dims)');

      // Test with very low threshold to see all matches
      final requestBody = {
        'vector': queryEmbedding,
        'topK': 10, // Get more results
        'includeMetadata': true,
        'includeValues': false,
      };
      
      print('🔬 Sending request to: $_pineconeHost/query');
      print('🔬 Index name: ${dotenv.env['PINECONE_INDEX_NAME']}');
      
      final response = await http.post(
        Uri.parse('$_pineconeHost/query'),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('🔬 Pinecone status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔬 Full Pinecone response: ${jsonEncode(data)}');
        
        final matches = data['matches'] as List? ?? [];
        print('🔬 Total matches: ${matches.length}');
        
        if (matches.isNotEmpty) {
          print('🔬 Match details:');
          for (int i = 0; i < matches.length; i++) {
            final match = matches[i];
            print('   [$i] ID: ${match['id']}, Score: ${match['score']}, Metadata: ${match['metadata']}');
          }
          
          // Test different thresholds
          final thresholds = [0.0, 0.3, 0.5, 0.7, 0.8, 0.9];
          for (double threshold in thresholds) {
            final filtered = matches.where((m) => (m['score'] as double) >= threshold).length;
            print('🔬 Threshold $threshold: $filtered matches');
          }
        } else {
          print('🔬 ❌ No matches returned from Pinecone');
          print('🔬 This suggests either:');
          print('     - Index is empty');
          print('     - Wrong index name');
          print('     - Dimension mismatch');
        }
        
        return {
          'success': true,
          'total_matches': matches.length,
          'matches': matches,
          'raw_response': data,
        };
      } else {
        print('🔬 ❌ Pinecone error: ${response.statusCode}');
        print('🔬 Response: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('🔬 ❌ Debug search failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test configuration with detailed output
  Future<Map<String, dynamic>> testConfiguration() async {
    final results = <String, dynamic>{
      'openai_available': false,
      'pinecone_available': false,
      'supabase_available': false,
      'errors': <String>[],
    };

    // Test OpenAI embedding
    try {
      print('🧪 Testing OpenAI embedding...');
      await generateEmbedding('test');
      results['openai_available'] = true;
      print('✅ OpenAI embedding test passed');
    } catch (e) {
      results['errors'].add('OpenAI: $e');
      print('❌ OpenAI embedding test failed: $e');
    }

    // Test Pinecone (simple ping)
    try {
      print('🧪 Testing Pinecone connection...');
      final response = await http.get(
        Uri.parse('$_pineconeHost/describe_index_stats'),
        headers: {'Api-Key': _pineconeApiKey},
      );
      if (response.statusCode == 200) {
        results['pinecone_available'] = true;
        print('✅ Pinecone test passed');
      } else {
        results['errors'].add('Pinecone: HTTP ${response.statusCode}');
        print('❌ Pinecone test failed: ${response.statusCode}');
      }
    } catch (e) {
      results['errors'].add('Pinecone: $e');
      print('❌ Pinecone test failed: $e');
    }

    // Test Supabase (simple ping)
    try {
      print('🧪 Testing Supabase connection...');
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/'),
        headers: {
          'Authorization': 'Bearer $_supabaseServiceKey',
          'apikey': _supabaseServiceKey,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 404) { // 404 is OK for root endpoint
        results['supabase_available'] = true;
        print('✅ Supabase test passed');
      } else {
        results['errors'].add('Supabase: HTTP ${response.statusCode}');
        print('❌ Supabase test failed: ${response.statusCode}');
      }
    } catch (e) {
      results['errors'].add('Supabase: $e');
      print('❌ Supabase test failed: $e');
    }

    return results;
  }

  /// Generate embeddings using OpenAI
  Future<List<double>> generateEmbedding(String text) async {
    try {
      print('🔍 Generating embedding for text: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
      print('🔧 Using API Key: ${_openaiApiKey.isNotEmpty ? "✅ Set (${_openaiApiKey.length} chars)" : "❌ Missing"}');
      print('🔧 Using model: $_embeddingModel');
      print('🔧 Base URL: ${dotenv.env['OPENAI_BASE_URL']}');

      if (_openaiApiKey.isEmpty) {
        throw Exception('OpenAI API key is not configured');
      }

      if (text.trim().isEmpty) {
        throw Exception('Text for embedding cannot be empty');
      }

      final requestBody = {
        'model': _embeddingModel,
        'input': text.trim(),
      };

      print('📤 Sending request to OpenAI...');
      
      final response = await http.post(
        Uri.parse('${dotenv.env['OPENAI_BASE_URL']}/embeddings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: jsonEncode(requestBody),
      );

      print('📥 OpenAI response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data'] == null || data['data'].isEmpty) {
          throw Exception('No embedding data in response: ${response.body}');
        }
        
        final embedding = List<double>.from(data['data'][0]['embedding']);
        print('✅ Embedding generated successfully (${embedding.length} dimensions)');
        return embedding;
      } else {
        print('❌ OpenAI API error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI API returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 Embedding generation failed: $e');
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Network error - check internet connection: $e');
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        throw Exception('Invalid API key - check OPENAI_API_KEY: $e');
      } else if (e.toString().contains('429')) {
        throw Exception('Rate limit exceeded - try again later: $e');
      } else {
        throw Exception('Embedding generation error: $e');
      }
    }
  }

  /// Search for similar vectors in Pinecone
  Future<List<Map<String, dynamic>>> searchSimilarVectors(
    String query, {
    int topK = 5,
    double scoreThreshold = 0.5, // Lowered from 0.7 to capture more relevant matches
    String? contextFilter,
  }) async {
    try {
      print('🔍 Searching vectors for query: "$query"');
      print('📐 Parameters: topK=$topK, scoreThreshold=$scoreThreshold');
      
      // Generate embedding for the query
      final queryEmbedding = await generateEmbedding(query);
      print('📊 Query embedding generated: ${queryEmbedding.length} dimensions');
      print('📊 First 5 values: ${queryEmbedding.take(5).toList()}');

      // Search in Pinecone
      final requestBody = {
        'vector': queryEmbedding,
        'topK': topK,
        'includeMetadata': true,
        'includeValues': false,
      };

      // Add context filter if provided
      if (contextFilter != null && contextFilter.isNotEmpty) {
        requestBody['filter'] = {
          'context': {'\$eq': contextFilter}
        };
        print('🎯 Applied context filter: $contextFilter');
      }
      
      print('🌲 Sending Pinecone request to: $_pineconeHost/query');
      print('🌲 Request body keys: ${requestBody.keys.toList()}');
      
      final response = await http.post(
        Uri.parse('$_pineconeHost/query'),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
        body: jsonEncode(requestBody),
      );

      print('🌲 Pinecone response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🌲 Pinecone response: ${jsonEncode(data)}');
        
        final matches = data['matches'] as List;
        print('🎯 Total matches found: ${matches.length}');
        
        // Log each match details
        for (int i = 0; i < matches.length; i++) {
          final match = matches[i];
          print('🎯 Match $i: score=${match['score']}, id=${match['id']}, metadata=${match['metadata']}');
        }
        
        // Filter by score threshold
        final filteredMatches = matches
            .where((match) => (match['score'] as double) >= scoreThreshold)
            .toList();
            
        print('✅ Filtered matches (score >= $scoreThreshold): ${filteredMatches.length}');
        for (int i = 0; i < filteredMatches.length; i++) {
          final match = filteredMatches[i];
          print('✅ Filtered match $i: score=${match['score']}, id=${match['id']}');
        }

        return filteredMatches.cast<Map<String, dynamic>>();
      } else {
        print('❌ Pinecone error: ${response.statusCode} - ${response.body}');
        throw Exception('Pinecone search failed: ${response.body}');
      }
    } catch (e) {
      print('💥 Vector search error: $e');
      throw Exception('Error searching vectors: $e');
    }
  }

  /// Retrieve content from Supabase based on IDs
  Future<List<Map<String, dynamic>>> retrieveContent(List<String> contentIds) async {
    try {
      print('📚 Retrieving content for ${contentIds.length} IDs: $contentIds');
      
      // First, let's try to query with different possible field names
      final possibleFields = ['id', 'chunk_id', 'doc_id'];
      List<Map<String, dynamic>> results = [];
      
      for (String field in possibleFields) {
        if (results.isNotEmpty) break; // Stop if we found results
        
        try {
          // Construct the filter for Supabase
          final idsFilter = contentIds.map((id) => '$field.eq.$id').join(',');
          final url = '$_supabaseUrl/rest/v1/document_chunks?or=($idsFilter)&select=*';
          
          print('📚 Trying Supabase query with field "$field": $url');
          
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_supabaseServiceKey',
              'apikey': _supabaseServiceKey,
            },
          );

          print('📚 Supabase response status for field "$field": ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as List;
            print('📚 Retrieved ${data.length} document_chunks using field "$field"');
            
            if (data.isNotEmpty) {
              results = data.cast<Map<String, dynamic>>();
              print('📚 Success! Using field "$field" for content retrieval');
              break;
            }
          } else {
            print('📚 Supabase error for field "$field": ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          print('📚 Error trying field "$field": $e');
        }
      }
      
      if (results.isEmpty) {
        print('📚 ❌ No content found with any field. Checking table structure...');
        // Let's try to get table info
        try {
          final response = await http.get(
            Uri.parse('$_supabaseUrl/rest/v1/document_chunks?limit=1&select=*'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_supabaseServiceKey',
              'apikey': _supabaseServiceKey,
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as List;
            if (data.isNotEmpty) {
              print('📚 Sample document structure: ${data[0].keys.toList()}');
            }
          }
        } catch (e) {
          print('📚 Could not fetch table structure: $e');
        }
      }
      
      // Log retrieved content details
      for (int i = 0; i < results.length; i++) {
        final doc = results[i];
        print('📚 Document $i: id=${doc['id']}, chunk_id=${doc['chunk_id']}, title=${doc['title'] ?? 'N/A'}, content_length=${(doc['content'] ?? doc['text'] ?? '').toString().length}');
      }
      
      return results;
    } catch (e) {
      print('💥 Content retrieval error: $e');
      throw Exception('Error retrieving content: $e');
    }
  }

  /// Perform RAG query: search vectors and retrieve content
  Future<Map<String, dynamic>> performRagQuery(
    String query, {
    int topK = 5,
    double scoreThreshold = 0.5, // Lowered from 0.7 to capture more relevant matches
    String? contextFilter,
  }) async {
    try {
      print('🔍 RAG Query: $query');
      
      // Step 1: Search for similar vectors
      final similarVectors = await searchSimilarVectors(
        query,
        topK: topK,
        scoreThreshold: scoreThreshold,
        contextFilter: contextFilter,
      );

      print('Found ${similarVectors.length} similar vectors');

      if (similarVectors.isEmpty) {
        return {
          'query': query,
          'results': [],
          'context': '',
          'message': 'No relevant content found for your query.',
        };
      }

      // Step 2: Extract content IDs from metadata
      final contentIds = similarVectors
          .map((match) {
            final metadata = match['metadata'];
            // Use chunk_id as the main identifier
            return metadata?['chunk_id']?.toString();
          })
          .where((id) => id != null)
          .cast<String>()
          .toList();

      print('📄 Extracted content IDs: $contentIds');
      print('📄 Sample metadata fields: ${similarVectors.isNotEmpty ? similarVectors[0]['metadata']?.keys.toList() : 'none'}');
      
      if (contentIds.isEmpty) {
        print('⚠️ No content IDs found in vector metadata');
        return {
          'query': query,
          'results': [],
          'context': '',
          'message': 'Vector matches found but no content IDs in metadata.',
        };
      }

      // Step 3: Retrieve full content from Supabase
      final contentResults = await retrieveContent(contentIds);
      
      if (contentResults.isEmpty) {
        print('⚠️ No content retrieved from Supabase for IDs: $contentIds');
        return {
          'query': query,
          'results': [],
          'context': '',
          'message': 'Content IDs found but no matching document_chunks in database.',
        };
      }

      // Step 4: Combine results with scores
      final enrichedResults = <Map<String, dynamic>>[];
      for (int i = 0; i < similarVectors.length; i++) {
        final vector = similarVectors[i];
        final contentId = vector['metadata']?['chunk_id']?.toString();
        print('🔗 Processing vector $i: contentId=$contentId, score=${vector['score']}');
        // Find corresponding content by chunk_id
        final content = contentResults.firstWhere(
          (c) => c['chunk_id'].toString() == contentId,
          orElse: () => <String, dynamic>{},
        );
        if (content.isNotEmpty) {
          print('✅ Content found for chunk_id $contentId');
          enrichedResults.add({
            'score': vector['score'],
            'metadata': vector['metadata'],
            'content': content,
          });
        } else {
          print('❌ No content found for chunk_id $contentId');
        }
      }

      print('🎯 Final enriched results: ${enrichedResults.length}');

      // Step 5: Create context string for AI
    final contextParts = enrichedResults
      .map((result) => result['content']['chunk_text'] ?? '')
      .where((text) => text.isNotEmpty)
      .toList();

    final context = contextParts.join('\n\n---\n\n');
      
      print('📝 Context length: ${context.length} characters');
      print('📝 Context preview: ${context.length > 200 ? context.substring(0, 200) + "..." : context}');

      print('✅ RAG query completed with ${enrichedResults.length} results');

      return {
        'query': query,
        'results': enrichedResults,
        'context': context,
        'summary': {
          'total_results': enrichedResults.length,
          'avg_score': enrichedResults.isNotEmpty 
              ? enrichedResults.map((r) => r['score'] as double).reduce((a, b) => a + b) / enrichedResults.length
              : 0.0,
        },
      };
    } catch (e) {
      print('❌ RAG query error: $e');
      throw Exception('RAG query failed: $e');
    }
  }

  /// Generate AI response using retrieved context
  Future<String> generateContextualResponse(
    String query,
    String context, {
    String? systemPrompt,
  }) async {
    try {
      print('🤖 Generating AI response for query: "$query"');
      print('🤖 Context length: ${context.length} characters');

      final defaultSystemPrompt = '''
Tu es un assistant IA spécialisé en astrologie et spiritualité. Utilise les informations contextuelles fournies pour répondre à la question de l'utilisateur de manière précise et pertinente.

Si les informations contextuelles ne contiennent pas assez d'éléments pour répondre à la question, dis-le clairement et propose des suggestions alternatives.
''';

      final finalSystemPrompt = systemPrompt ?? defaultSystemPrompt;
      print('🤖 System prompt length: ${finalSystemPrompt.length} characters');

      // Construct user message with context + query
      final userMessage = context.isNotEmpty
          ? 'Contexte disponible:\n$context\n\nQuestion: $query'
          : query;

      final requestBody = {
        'model': dotenv.env['OPENAI_CHAT_MODEL'] ?? 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content': finalSystemPrompt,
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
        'temperature': 0.7,
        'max_completion_tokens': 1500,
      };
      
      print('🤖 Sending request to OpenAI chat API');
      print('🤖 Request body preview: model=${requestBody['model']}, messages count=${(requestBody['messages'] as List).length}');
      print('🤖 System message length: ${(requestBody['messages'] as List)[0]['content'].length}');
      print('🤖 User message length: ${(requestBody['messages'] as List)[1]['content'].length}');

      final response = await http.post(
        Uri.parse('${dotenv.env['OPENAI_BASE_URL']}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: jsonEncode(requestBody),
      );

      print('🤖 OpenAI chat response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🤖 OpenAI response data: ${jsonEncode(data)}');
        
        if (data['choices'] == null || data['choices'].isEmpty) {
          print('❌ OpenAI response has no choices');
          throw Exception('OpenAI returned no choices in response');
        }
        
        final choice = data['choices'][0];
        if (choice['message'] == null || choice['message']['content'] == null) {
          print('❌ OpenAI response has no content in message');
          print('🤖 Choice data: ${jsonEncode(choice)}');
          throw Exception('OpenAI returned no content in message');
        }
        
        final aiResponse = choice['message']['content'].toString();
        print('✅ AI response generated: ${aiResponse.length} characters');
        print('✅ AI response preview: ${aiResponse.length > 200 ? aiResponse.substring(0, 200) + "..." : aiResponse}');
        return aiResponse;
      } else {
        print('❌ OpenAI chat error: ${response.statusCode} - ${response.body}');
        throw Exception('OpenAI response generation failed: ${response.body}');
      }
    } catch (e) {
      print('💥 AI response generation error: $e');
      throw Exception('Error generating contextual response: $e');
    }
  }

  /// Complete RAG pipeline: query, retrieve, and generate response
  Future<Map<String, dynamic>> askQuestion(
    String question, {
    int topK = 5,
    double scoreThreshold = 0.5, // Lowered from 0.7 to capture more relevant matches
    String? systemPrompt,
    String? contextFilter,
  }) async {
    try {
      print('🚀 =================== RAG PIPELINE START ===================');
      print('🤖 Question: "$question"');
      print('🔧 Parameters: topK=$topK, scoreThreshold=$scoreThreshold');
      
      // Step 1: Perform RAG query
      print('📊 Step 1: Performing RAG query...');
      final ragResults = await performRagQuery(
        question,
        topK: topK,
        scoreThreshold: scoreThreshold,
        contextFilter: contextFilter,
      );

      // Step 2: Generate contextual response
      final context = ragResults['context'] as String;
      print('📝 Step 2: Generating AI response...');
      print('📝 Context available: ${context.isNotEmpty ? "YES" : "NO"} (${context.length} chars)');
      
      String aiResponse;

      if (context.isNotEmpty) {
        print('✅ Context found, generating AI response...');
        aiResponse = await generateContextualResponse(
          question,
          context,
          systemPrompt: systemPrompt,
        );
      } else {
        print('⚠️ No context found, using fallback response');
        aiResponse = "Je n'ai pas trouvé d'informations pertinentes dans ma base de connaissances pour répondre à votre question. Pouvez-vous reformuler ou poser une question différente ?";
      }

      print('🎯 =================== RAG PIPELINE END ===================');
      print('✅ Pipeline completed successfully');
      print('📊 Results summary:');
      print('   - Sources found: ${(ragResults['results'] as List).length}');
      print('   - Context length: ${context.length}');
      print('   - AI response length: ${aiResponse.length}');

      return {
        'question': question,
        'answer': aiResponse,
        'sources': ragResults['results'],
        'context_used': context,
        'metadata': ragResults['summary'],
      };
    } catch (e) {
      print('💥 =================== RAG PIPELINE ERROR ===================');
      print('❌ Error details: $e');
      print('💥 ============================================================');
      throw Exception('RAG pipeline failed: $e');
    }
  }
}